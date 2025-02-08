# frozen_string_literal: true

namespace :exwiw do
  namespace :schema do
    desc "Generate schema from application"
    task generate: :environment do
      require "json"
      require "exwiw"

      Rails.application.eager_load!

      relationships = []

      ActiveRecord::Base.descendants.each do |model|
        next if model.abstract_class?

        belongs_to_relations = model.reflect_on_all_associations(:belongs_to).map do |assoc|
          if assoc.polymorphic?
            {
              polymorphic: true,
              polymorphic_name: assoc.name,
              foreign_type: assoc.foreign_type,
              foreign_key: assoc.foreign_key,
            }
          else
            {
              polymorphic: false,
              table_name: assoc.table_name,
              foreign_key: assoc.foreign_key,
            }
          end
        end

        polymorphic_as = []
        model.reflect_on_all_associations(:has_many).each do |assoc|
          polymorphic_as << assoc.options[:as] if assoc.options[:as]
        end
        model.reflect_on_all_associations(:has_one).each do |assoc|
          polymorphic_as << assoc.options[:as] if assoc.options[:as]
        end

        columns = model.column_names.map { |name| { name: name } }

        # XXX use Table
        relationships << {
          name: model.table_name,
          primary_key: model.primary_key,
          belongs_to_relations: belongs_to_relations,
          polymorphic_as: polymorphic_as,
          columns: columns,
        }
      end

      # XXX: Pass target config from arg
      db_config = Rails.configuration.database_configuration[Rails.env]["replica"]
      # XXX Use Config
      config = {
        database: {
          adapter: db_config["adapter"],
          name: db_config["database"],
          encoding: db_config["encoding"],
        },
        tables: relationships,
      }

      File.write("schema.json", JSON.pretty_generate(config))
    end
  end
end
