# frozen_string_literal: true

module Exwiw
  module Adapter
    class Mysql2Adapter < Base
      def execute(query_ast)
        sql = compile_ast(query_ast)

        connection.query(sql, cast: false, as: :array)
      end

      def to_bulk_insert(results, table)
        table_name = table.name

        value_list = results.map do |row|
          quoted_values = row.map do |value|
            case value
            when nil
              "NULL"
            when String
              "'#{value}'"
            else
              value
            end
          end
          "(" + quoted_values.join(', ') + ")"
        end
        values = value_list.join(",\n")

        column_names = table.columns.map(&:name).join(', ')
        "INSERT INTO #{table_name} (#{column_names}) VALUES\n#{values};"
      end

      def to_bulk_delete(select_query_ast, table)
        raise NotImplementedError unless select_query_ast.is_a?(Exwiw::QueryAst::Select)

        sql = "DELETE FROM #{select_query_ast.from_table_name}"

        if select_query_ast.join_clauses.empty?
          compiled_where_conditions = select_query_ast.where_clauses.map do |where|
            compile_where_condition(where, select_query_ast.from_table_name)
          end

          if compiled_where_conditions.size > 0
            sql += "\nWHERE "
            sql += compiled_where_conditions.join(' AND ')
          end
          sql += ";"

          return sql
        end

        subquery_ast = Exwiw::QueryAst::Select.new
        first_join = select_query_ast.join_clauses.first.clone

        subquery_ast.from(first_join.join_table_name)
        primay_key_col = table.columns.find { |col| col.name == table.primary_key }
        subquery_ast.select([primay_key_col])
        select_query_ast.join_clauses[1..].each do |join|
          subquery_ast.join(join)
        end
        first_join.where_clauses.each do |where|
          subquery_ast.where(where)
        end

        foreign_key = first_join.foreign_key
        subquery_sql = compile_ast(subquery_ast)
        sql += "\nWHERE #{select_query_ast.from_table_name}.#{foreign_key} IN (#{subquery_sql});"

        sql
      end

      def compile_ast(query_ast)
        raise NotImplementedError unless query_ast.is_a?(Exwiw::QueryAst::Select)

        sql = "SELECT "
        sql += query_ast.columns.map { |col| compile_column_name(query_ast, col) }.join(', ')
        sql += " FROM #{query_ast.from_table_name}"

        query_ast.join_clauses.each do |join|
          sql += " JOIN #{join.join_table_name} ON #{query_ast.from_table_name}.#{join.foreign_key} = #{join.join_table_name}.#{join.primary_key}"

          join.where_clauses.each do |where|
            compiled_where_condition = compile_where_condition(where, join.join_table_name)
            sql += " AND #{compiled_where_condition}"
          end
        end

        if query_ast.where_clauses.any?
          sql += " WHERE "
          sql += query_ast.where_clauses.map { |where| compile_where_condition(where, query_ast.from_table_name) }.join(' AND ')
        end

        sql
      end

      private def compile_where_condition(where_clause, table_name)
        key = "#{table_name}.#{where_clause.column_name}"

        if where_clause.operator == :eq
          values = where_clause.value.map { |v| escape_value(v) }

          if values.size == 1
            "#{key} = #{values.first}"
          else
            "#{key} IN (#{values.join(', ')})"
          end
        else
          raise "Unsupported operator: #{where_clause.operator}"
        end
      end

      private def escape_value(value)
        if value.is_a?(String)
          "'#{value}'"
        else
          value
        end
      end

      private def compile_column_name(ast, column)
        case column
        when Exwiw::QueryAst::ColumnValue::Plain
          "#{ast.from_table_name}.#{column.name}"
        when Exwiw::QueryAst::ColumnValue::RawSql
          column.value
        when Exwiw::QueryAst::ColumnValue::ReplaceWith
          parts = column.value.scan(/[^{}]+|\{[^{}]*\}/).map do |part|
            if part.start_with?('{')
              name = part[1..-2]
              "#{ast.from_table_name}.#{name}"
            else
              "'#{part}'"
            end
          end

          replaced = parts.join(", ")
          "CONCAT(#{replaced})"
        else
          raise "Unreachable case: #{column.inspect}"
        end
      end

      private def connection
        @connection ||=
          begin
            require 'mysql2'
            Mysql2::Client.new(
              host: @connection_config.host,
              port: @connection_config.port,
              username: @connection_config.user,
              password: @connection_config.password,
              database: @connection_config.database_name
            )
          end
      end
    end
  end
end
