# frozen_string_literal: true

namespace :exwiw do
  namespace :schema do
    desc "Generate schema from application"
    task generate: :environment do
      require "json"
      require "exwiw"

      Rails.application.eager_load!

      table_by_name = {}

      ActiveRecord::Base.descendants.each do |model|
        next if model.abstract_class?
        next if table_by_name[model.table_name]

        belongs_tos = model.reflect_on_all_associations(:belongs_to).map do |assoc|
          if assoc.polymorphic?
            # XXX: Support polymorphic
            next
          else
            Exwiw::BelongsTo.from_symbol_keys({
              table_name: assoc.table_name,
              foreign_key: assoc.foreign_key,
            })
          end
        end

        columns = model.column_names.map do |name|
          Exwiw::TableColumn.from_symbol_keys({ name: name })
        end

        table = Exwiw::Table.from_symbol_keys({
          name: model.table_name,
          primary_key: model.primary_key,
          belongs_tos: belongs_tos.compact,
          columns: columns,
        })
        table_by_name[table.name] = table
      end

      tables = table_by_name.values.sort_by! { |table| table.name }

      config = Exwiw::Config.from_symbol_keys({ tables: tables })

      File.write("schema.json", JSON.pretty_generate(config.to_hash))
    end
  end
end
