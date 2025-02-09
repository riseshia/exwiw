# frozen_string_literal: true

module Exwiw
  module QueryAst
    class JoinClause
      attr_reader :foreign_key, :join_table_name, :primary_key, :where_clauses

      def initialize(foreign_key:, join_table_name:, primary_key:, where_clauses: [])
        @foreign_key = foreign_key
        @join_table_name = join_table_name
        @primary_key = primary_key
        @where_clauses = where_clauses
      end

      def to_h
        hash = {
          foreign_key: foreign_key,
          join_table_name: join_table_name,
          primary_key: primary_key,
        }
        hash[:where_clauses] = where_clauses.map(&:to_h) if where_clauses.size.positive?
        hash
      end
    end

    WhereClause = Struct.new(:column_name, :operator, :value, keyword_init: true) do
      def to_h
        {
          column_name: column_name,
          operator: operator,
          value: value
        }
      end
    end

    class Select
      attr_reader :from_table_name, :column_names, :where_clauses, :join_clauses

      def initialize
        @from_table_name = nil
        @column_names = nil
        @where_clauses = []
        @join_clauses = []
      end

      def from(table)
        @from_table_name = table
      end

      def select(columns_clause)
        @column_names = columns_clause
      end

      def where(where_clause)
        @where_clauses << where_clause
      end

      def join(join_clause)
        @join_clauses << join_clause
      end
    end
  end
end
