# frozen_string_literal: true

module Exwiw
  module QueryAstBuilder
    module_function

    def run(table_name, all_tables, dump_target)
      table_by_name = all_tables.each_with_object({}) do |table, acc|
        acc[table.name] = table
      end

      table = table_by_name.fetch(table_name)

      where_clauses = build_where_clauses(table, dump_target)
      join_clauses = build_join_clauses(table, table_by_name, dump_target)

      QueryAst::Select.new.tap do |select|
        select.from(table.name)
        select.select(table.column_names)
        join_clauses.each { |join_clause| select.join(join_clause) }
        where_clauses.each { |where_clause| select.where(where_clause) }
      end
    end

    private def build_join_clauses(table, table_by_name, dump_target)
      path_tables = find_path_to_dump_target(table, table_by_name, dump_target)
      # the path is empty, it means that the table is not related to the dump target
      # the path is 1, it's impossible case
      # the path is 2, it means that the table is directly related to the dump target, no need to join
      return [] if path_tables.size < 3

      join_clauses = []

      path_tables.each_cons(2) do |from_table_name, to_table_name|
        from_table = table_by_name[from_table_name]
        to_table = table_by_name[to_table_name]

        relation = from_table.belongs_to(to_table_name)

        join_clauses.push(
          QueryAst::JoinClause.new(
            foreign_key: relation.foreign_key,
            join_table_name: to_table.name,
            primary_key: to_table.primary_key,
            where_clauses: []
          )
        )
      end

      join_clauses.last.where_clauses.push Exwiw::QueryAst::WhereClause.new(
        column_name: 'id',
        operator: :eq,
        value: dump_target.ids
      )

      join_clauses
    end

    private def build_where_clauses(table, dump_target)
      clauses = []

      if table.name == dump_target.table_name
        clauses.push Exwiw::QueryAst::WhereClause.new(
          column_name: 'id',
          operator: :eq,
          value: dump_target.ids
        )

        return clauses
      end

      belongs_to = table.belongs_to(dump_target.table_name)
      return clauses if belongs_to.nil?

      clauses.push(
        column_name: belongs_to.foreign_key,
        operator: :eq,
        value: dump_target.ids
      )

      clauses
    end

    private def find_path_to_dump_target(table, table_by_name, dump_target)
      return [] if table.name == dump_target.table_name

      visited = {}
      queue = [[table.name, []]]

      until queue.empty?
        current_table_name, path = queue.shift
        current_table = table_by_name[current_table_name]

        next if visited[current_table_name]
        visited[current_table_name] = true

        current_table.belongs_tos.each do |relation|
          next_table_name = relation.table_name
          next_path = path + [current_table_name]

          return next_path + [dump_target.table_name] if next_table_name == dump_target.table_name

          queue.push([next_table_name, next_path])
        end
      end

      queue
    end
  end
end
