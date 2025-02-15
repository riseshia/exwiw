# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Exwiw::QueryAstBuilder do
  describe '.run' do
    let(:dump_target) { Exwiw::DumpTarget.new(table_name: 'shops', ids: [1]) }
    let(:all_tables) do
      [
        users_table(:sqlite3),
        shops_table(:sqlite3),
        products_table(:sqlite3),
        orders_table(:sqlite3),
        order_items_table(:sqlite3),
        transactions_table(:sqlite3),
        system_announcements_table(:sqlite3),
      ]
    end
    let(:table_by_name) do
      all_tables.each_with_object({}) do |table, hash|
        hash[table.name] = table
      end
    end
    let(:logger) { Logger.new(nil) }
    let(:built_query_ast) { described_class.run(table.name, table_by_name, dump_target, logger) }

    def simply_columns(columns)
      columns.map do |c|
        case c
        when Exwiw::QueryAst::ColumnValue::Plain
          { name: c.name }
        when Exwiw::QueryAst::ColumnValue::ReplaceWith
          { name: c.name, replace_with: c.value }
        when Exwiw::QueryAst::ColumnValue::RawSql
          { name: c.name, raw_sql: c.value }
        end
      end
    end

    context 'when the table is same as dump target table' do
      let(:table) { shops_table(:sqlite3) }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('shops')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'name' },
          { name: 'updated_at' },
          { name: 'created_at' },
        ])
        expect(built_query_ast.join_clauses).to eq([])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([
          { column_name: 'id', operator: :eq, value: [1] }
        ])
      end
    end

    context 'when the table has foreign key to dump target table' do
      let(:table) { users_table(:sqlite3) }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('users')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'name', raw_sql: "('masked' || users.id)" },
          { name: 'email', replace_with: 'masked{id}@example.com' },
          { name: 'shop_id' },
          { name: 'updated_at' },
          { name: 'created_at' },
        ])
        expect(built_query_ast.join_clauses.map(&:to_h)).to eq([])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([
          { column_name: 'shop_id', operator: :eq, value: [1] },
        ])
      end
    end

    context 'when the table is N:M relation to dump target table' do
      let(:table) { order_items_table(:sqlite3) }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('order_items')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'quantity' },
          { name: 'order_id' },
          { name: 'product_id' },
          { name: 'updated_at' },
          { name: 'created_at' },
        ])
        expect(built_query_ast.join_clauses.map(&:to_h)).to eq([{
          base_table_name: 'order_items',
          foreign_key: 'order_id',
          join_table_name: 'orders',
          primary_key: 'id',
          where_clauses: [{ column_name: 'shop_id', operator: :eq, value: [1] }] },
        ])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([])
      end
    end

    context 'when the table is indirect relation with dump target table' do
      let(:table) { transactions_table(:sqlite3) }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('transactions')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'type' },
          { name: 'amount' },
          { name: 'order_id' },
          { name: 'updated_at' },
          { name: 'created_at' },
        ])
        expect(built_query_ast.join_clauses.map(&:to_h)).to eq([{
          base_table_name: 'transactions',
          foreign_key: 'order_id',
          join_table_name: 'orders',
          primary_key: 'id',
          where_clauses: [{ column_name: 'shop_id', operator: :eq, value: [1] }] },
        ])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([])
      end
    end

    context 'when the table has no relation with dump target table' do
      let(:table) { system_announcements_table(:sqlite3) }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('system_announcements')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'title' },
          { name: 'content' },
          { name: 'updated_at' },
          { name: 'created_at' },
        ])
        expect(built_query_ast.join_clauses).to eq([])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([])
      end
    end
  end
end
