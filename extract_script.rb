require_relative 'config/environment'

Rails.application.eager_load!

relationships = []

ActiveRecord::Base.descendants.each do |model|
  next if model.abstract_class?

  puts "Model: #{model}"
  belongs_to_relations = model.reflect_on_all_associations(:belongs_to).map do |assoc|
    puts "- belongs_to: #{assoc.class_name}"
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

  relationships << {
    name: model.table_name,
    primary_key: model.primary_key,
    belongs_to_relations: belongs_to_relations,
    polymorphic_as: polymorphic_as,
    columns: columns,
  }
end

require "json"

db_config = Rails.configuration.database_configuration[Rails.env]["replica"]
pp db_config
config = {
  database: {
    adapter: db_config["adapter"],
    name: db_config["database"],
    encoding: db_config["encoding"],
  },
  tables: relationships,
}

File.write("schema.json", JSON.pretty_generate(config))
