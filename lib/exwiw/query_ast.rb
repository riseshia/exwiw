# frozen_string_literal: true

module Exwiw
  module QueryAst
    class JoinClause
      attr_reader :base_table_name, :foreign_key, :join_table_name, :primary_key, :where_clauses

      def initialize(base_table_name:, foreign_key:, join_table_name:, primary_key:, where_clauses: [])
        @base_table_name = base_table_name
        @foreign_key = foreign_key
        @join_table_name = join_table_name
        @primary_key = primary_key
        @where_clauses = where_clauses
      end

      def to_h
        hash = {
          base_table_name: base_table_name,
          foreign_key: foreign_key,
          join_table_name: join_table_name,
          primary_key: primary_key,
        }
        if where_clauses.size.positive?
          hash[:where_clauses] = where_clauses.map { |wc| wc.is_a?(String) ? wc : wc.to_h }
        end
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

    module ColumnValue
      Base = Struct.new(:name, :value, keyword_init: true)
      Plain = Class.new(Base)
      ReplaceWith = Class.new(Base)
      RawSql = Class.new(Base)
    end

    class Select
      attr_reader :from_table_name, :columns, :where_clauses, :join_clauses

      def initialize
        @from_table_name = nil
        @columns = []
        @where_clauses = []
        @join_clauses = []
      end

      def from(table)
        @from_table_name = table
      end

      def select(columns)
        @columns = map_column_value(columns)
      end

      def where(where_clause)
        @where_clauses << where_clause
      end

      def join(join_clause)
        @join_clauses << join_clause
      end

      private def map_column_value(columns)
        columns.map do |c|
          if c.raw_sql
            QueryAst::ColumnValue::RawSql.new(name: c.name, value: c.raw_sql)
          elsif c.replace_with
            QueryAst::ColumnValue::ReplaceWith.new(name: c.name, value: c.replace_with)
          else
            QueryAst::ColumnValue::Plain.new(name: c.name, value: c.name)
          end
        end
      end
    end
  end
end
