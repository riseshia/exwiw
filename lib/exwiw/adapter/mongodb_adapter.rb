# frozen_string_literal: true

require 'json'

# NOTE: This adapter assumes a "flat" document schema where references between
# collections are expressed as scalar foreign keys (e.g. `shop_id` on `users`).
# It has not been validated against real-world MongoDB applications that rely
# heavily on embedded documents / arrays of subdocuments — the forward fan-out
# strategy here cannot follow references that live inside embedded structures.
module Exwiw
  module Adapter
    class MongodbAdapter < Base
      def initialize(connection_config, logger)
        super
        @state = {}
      end

      def build_query(table, dump_target, table_by_name)
        reject_raw_sql_columns!(table)
        reject_filter!(table)

        filter =
          if table.name == dump_target.table_name
            { table.primary_key => { "$in" => coerce_ids(dump_target.ids) } }
          else
            constrained = table.belongs_tos.select do |relation|
              @state.key?(relation.table_name) && !@state[relation.table_name].empty?
            end

            if constrained.empty?
              {}
            else
              constrained.each_with_object({}) do |relation, acc|
                acc[relation.foreign_key] = { "$in" => @state[relation.table_name] }
              end
            end
          end

        Exwiw::MongoQuery::Find.new(
          collection: table.name,
          primary_key: table.primary_key,
          filter: filter,
          projection: build_projection(table),
        )
      end

      def execute(query)
        @logger.debug("  Executing Mongo find on '#{query.collection}': filter=#{query.filter.inspect} projection=#{query.projection.inspect}")

        docs = db[query.collection].find(query.filter).projection(query.projection).to_a

        @state[query.collection] = docs.map { |doc| doc[query.primary_key] }

        docs
      end

      def to_bulk_insert(rows, table)
        rows.map do |doc|
          materialized = apply_replace_with(doc, table)
          JSON.generate(extended_json(materialized))
        end.join("\n")
      end

      def to_bulk_delete(_query, _table)
        raise NotImplementedError, "MongodbAdapter does not support bulk delete"
      end

      def output_extension
        'jsonl'
      end

      def supports_bulk_delete?
        false
      end

      # `--ids` from the CLI arrives as Strings. Mongo compares types strictly,
      # so integer-looking ids are coerced to Integer. Other strings (e.g. ObjectId
      # hex) are left as-is.
      private def coerce_ids(ids)
        Array(ids).map do |id|
          if id.is_a?(String) && id.match?(/\A-?\d+\z/)
            id.to_i
          else
            id
          end
        end
      end

      private def reject_raw_sql_columns!(table)
        raw = table.columns.select { |c| c.raw_sql }
        return if raw.empty?

        raise NotImplementedError,
              "raw_sql column is not supported by MongodbAdapter " \
              "(table: #{table.name}, columns: #{raw.map(&:name).join(', ')})"
      end

      private def reject_filter!(table)
        return if table.filter.nil? || table.filter.to_s.empty?

        raise NotImplementedError,
              "table-level `filter` is not supported by MongodbAdapter (table: #{table.name})"
      end

      private def build_projection(table)
        projection = {}
        # Always include primary key so masking templates referencing it work,
        # even if it is not declared in columns.
        projection[table.primary_key] = 1
        table.columns.each do |column|
          projection[column.name] = 1
        end
        projection
      end

      private def apply_replace_with(doc, table)
        masked = doc.dup
        table.columns.each do |column|
          next unless column.replace_with

          masked[column.name] = column.replace_with.gsub(/\{([^{}]+)\}/) do
            field = Regexp.last_match(1)
            value = masked.key?(field) ? masked[field] : doc[field]
            value.to_s
          end
        end
        masked
      end

      private def extended_json(doc)
        if doc.respond_to?(:as_extended_json)
          doc.as_extended_json(mode: :relaxed)
        else
          doc
        end
      end

      private def db
        @db ||=
          begin
            require 'mongo'
            address = "#{@connection_config.host}:#{@connection_config.port}"
            options = { database: @connection_config.database_name }
            if @connection_config.user && !@connection_config.user.to_s.empty?
              options[:user] = @connection_config.user
              options[:password] = @connection_config.password
            end
            Mongo::Logger.logger.level = ::Logger::WARN
            Mongo::Client.new([address], **options)
          end
      end
    end
  end
end
