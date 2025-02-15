# frozen_string_literal: true

namespace :exwiw do
  namespace :schema do
    desc "Generate schema from application"
    task generate: :environment do
      require "json"
      require "exwiw"
      require "fileutils"

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

        table = Exwiw::TableConfig.from_symbol_keys({
          name: model.table_name,
          primary_key: model.primary_key,
          belongs_tos: belongs_tos.compact,
          columns: columns,
        })
        table_by_name[table.name] = table
      end

      tables = table_by_name.values

      FileUtils.mkdir_p("exwiw")

      tables.each do |table|
        path = File.join("exwiw", "#{table.name}.json")
        File.write(path, JSON.pretty_generate(table.to_hash))
      end
    end
  end
end
