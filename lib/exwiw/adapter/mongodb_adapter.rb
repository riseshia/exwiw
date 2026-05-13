# frozen_string_literal: true

require 'json'

# NOTE: This adapter consumes MongodbCollectionConfig (`fields` instead of
# the SQL adapters' `columns`). It assumes a "flat" document schema where
# references between collections are expressed as scalar foreign keys
# (e.g. `shop_id` on `users`); the forward fan-out strategy here cannot
# follow references that live inside embedded structures.
module Exwiw
  module Adapter
    class MongodbAdapter < Base
      def self.table_config_class
        Exwiw::MongodbCollectionConfig
      end

      def initialize(connection_config, logger)
        super
        @state = {}
      end

      def build_query(config, dump_target, _config_by_name)
        reject_filter!(config)

        filter =
          if config.name == dump_target.table_name
            { config.primary_key => { "$in" => coerce_ids(dump_target.ids) } }
          else
            constrained = config.belongs_tos.select do |relation|
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
          collection: config.name,
          primary_key: config.primary_key,
          filter: filter,
          projection: build_projection(config),
        )
      end

      def execute(query)
        @logger.debug("  Executing Mongo find on '#{query.collection}': filter=#{query.filter.inspect} projection=#{query.projection.inspect}")

        docs = db[query.collection].find(query.filter).projection(query.projection).to_a

        @state[query.collection] = docs.map { |doc| doc[query.primary_key] }

        docs
      end

      def to_bulk_insert(rows, config)
        rows.map do |doc|
          apply_replace_with!(doc, config)
          JSON.generate(extended_json(doc))
        end.join("\n")
      end

      def to_bulk_delete(_query, _config)
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

      private def reject_filter!(config)
        return if config.filter.nil? || config.filter.to_s.empty?

        raise NotImplementedError,
              "collection-level `filter` is not supported by MongodbAdapter (collection: #{config.name})"
      end

      private def build_projection(config)
        projection = {}
        # Always include primary key so masking templates referencing it work,
        # even if it is not declared in fields.
        projection[config.primary_key] = 1
        config.fields.each do |field|
          projection[field.name] = 1
        end
        projection
      end

      private def apply_replace_with!(doc, config)
        config.fields.each do |field|
          next unless field.replace_with

          doc[field.name] = field.replace_with.gsub(/\{([^{}]+)\}/) do
            ref = Regexp.last_match(1)
            (doc.key?(ref) ? doc[ref] : nil).to_s
          end
        end
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
