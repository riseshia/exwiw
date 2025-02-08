module ComputeTableDependencies
  module_function

  def compute_table_dependencies(table, polymorphic_by_name)
    table.belongs_to_relations.each_with_object([]) do |relation, acc|
      if relation.polymorphic
        polymorphic_by_name[relation.polymorphic_name].each do |table_name|
          acc << table_name
        end
      else
        acc << relation.table_name
      end
    end
  end

  def run(tables)
    ordered_table_names = []

    polymorphic_by_name = tables.each_with_object({}) do |table, acc|
      table.polymorphic_as.each do |polymorphic|
        acc[polymorphic] ||= []
        acc[polymorphic] << table.name
      end
    end

    table_by_name = tables.each_with_object({}) do |table, acc|
      acc[table.name] = table
    end

    loop do
      break if table_by_name.empty?

      tables_with_no_dependencies = table_by_name.values.select do |table|
        not_resolved_names = compute_table_dependencies(table, polymorphic_by_name) - ordered_table_names - [table.name]

        not_resolved_names.empty?
      end

      tables_with_no_dependencies.each do |table|
        ordered_table_names << table.name
        table_by_name.delete(table.name)
      end
    end

    ordered_table_names
  end
end

