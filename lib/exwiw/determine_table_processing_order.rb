# frozen_string_literal: true

module Exwiw
  module DetermineTableProcessingOrder
    module_function

    # @param tables [Array<Exwiw::Table>] tables
    # @return [Array<String>] sorted table names
    def run(tables)
      return tables.map(&:name) if tables.size < 2

      ordered_table_names = []

      table_by_name = tables.each_with_object({}) do |table, acc|
        acc[table.name] = table
      end

      loop do
        break if table_by_name.empty?

        tables_with_no_dependencies = table_by_name.values.select do |table|
          not_resolved_names = compute_table_dependencies(table) - ordered_table_names - [table.name]

          not_resolved_names.empty?
        end

        tables_with_no_dependencies.each do |table|
          ordered_table_names << table.name
          table_by_name.delete(table.name)
        end
      end

      ordered_table_names
    end

    def compute_table_dependencies(table)
      table.belongs_tos.each_with_object([]) do |relation, acc|
        acc << relation.table_name
      end
    end
  end
end
