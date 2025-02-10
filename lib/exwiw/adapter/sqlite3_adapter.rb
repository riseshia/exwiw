# frozen_string_literal: true

module Exwiw
  module Adapter
    class Sqlite3Adapter < Base
      def execute(query_ast)
        sql = compile_ast(query_ast)

        connection.execute(sql)
      end

      def to_bulk_insert(results, table)
        table_name = table.name

        value_list = results.map do |row|
          quoted_values = row.map { |value| value.is_a?(String) ? "'#{value}'" : value }
          "(" + quoted_values.join(', ') + ")"
        end
        values = value_list.join(",\n")

        "INSERT INTO #{table_name} VALUES\n#{values};"
      end

      def to_bulk_delete(results, table)
        table_name = table.name
        primary_key = table.primary_key
        pk_idx = table.columns.find_index { |col| col.name == primary_key }

        pk_ids = results.map { |row| row[pk_idx].is_a?(String) ? "'#{row[pk_idx]}'" : row[pk_idx] }

        <<~SQL
          DELETE FROM #{table_name}
          WHERE #{primary_key} IN (#{pk_ids.join(', ')});
        SQL
      end

      def compile_ast(query_ast)
        raise NotImplementedError unless query_ast.is_a?(Exwiw::QueryAst::Select)

        sql = "SELECT "
        sql += query_ast.columns.map { |col| compile_column_name(query_ast, col) }.join(', ')
        sql += " FROM #{query_ast.from_table_name}"

        query_ast.join_clauses.each do |join|
          sql += " JOIN #{join.join_table_name} ON #{query_ast.from_table_name}.#{join.foreign_key} = #{join.join_table_name}.#{join.primary_key}"

          join.where_clauses.each do |where|
            sql += " AND #{join.join_table_name}.#{where.column_name} = #{where.value.first}"
          end
        end

        if query_ast.where_clauses.any?
          sql += " WHERE "
          sql += query_ast.where_clauses.map { |where| "#{query_ast.from_table_name}.#{where.column_name} = #{where.value.first}" }.join(' AND ')
        end

        sql
      end

      private def compile_column_name(ast, column)
        if column.is_a?(Exwiw::QueryAst::ColumnValue::ReplaceWith)
          replaced = column.value.gsub(/{[^}]+}/) do |m|
            inject_name = m[1..-2]
            "' || #{ast.from_table_name}.#{inject_name} || '"
          end

          "('#{replaced}')"
        else
          "#{ast.from_table_name}.#{column.value}"
        end
      end

      private def connection
        @connection ||=
          begin
            require 'sqlite3'
            SQLite3::Database.new(@connection_config.database_name)
          end
      end
    end
  end
end
