# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Exwiw::QueryAstBuilder do
  describe '.run' do
    let(:dump_target) { Exwiw::DumpTarget.new(table_name: 'shops', ids: [1]) }
    let(:all_tables) do
      [
        users_table,
        shops_table,
        products_table,
        orders_table,
        order_items_table,
        transactions_table,
        system_announcements_table,
      ]
    end
    let(:table_by_name) do
      all_tables.each_with_object({}) do |table, hash|
        hash[table.name] = table
      end
    end
    let(:built_query_ast) { described_class.run(table.name, table_by_name, dump_target) }

    def simply_columns(columns)
      columns.map do |c|
        case c
        when Exwiw::QueryAst::ColumnValue::Plain
          { name: c.name }
        when Exwiw::QueryAst::ColumnValue::ReplaceWith
          { name: c.name, replace_with: c.value }
        end
      end
    end

    context 'when the table is same as dump target table' do
      let(:table) { shops_table }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('shops')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'name' },
          { name: 'created_at' },
          { name: 'updated_at' },
        ])
        expect(built_query_ast.join_clauses).to eq([])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([
          { column_name: 'id', operator: :eq, value: [1] }
        ])
      end
    end

    context 'when the table has foreign key to dump target table' do
      let(:table) { users_table }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('users')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'name' },
          { name: 'email', replace_with: 'masked{id}@example.com' },
          { name: 'shop_id' },
          { name: 'created_at' },
          { name: 'updated_at' },
        ])
        expect(built_query_ast.join_clauses.map(&:to_h)).to eq([])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([
          { column_name: 'shop_id', operator: :eq, value: [1] },
        ])
      end
    end

    context 'when the table is N:M relation to dump target table' do
      let(:table) { order_items_table }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('order_items')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'quantity' },
          { name: 'order_id' },
          { name: 'product_id' },
          { name: 'created_at' },
          { name: 'updated_at' },
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
      let(:table) { transactions_table }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('transactions')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'type' },
          { name: 'amount' },
          { name: 'order_id' },
          { name: 'created_at' },
          { name: 'updated_at' },
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
      let(:table) { system_announcements_table }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('system_announcements')
        expect(simply_columns(built_query_ast.columns)).to eq([
          { name: 'id' },
          { name: 'title' },
          { name: 'content' },
          { name: 'created_at' },
          { name: 'updated_at' },
        ])
        expect(built_query_ast.join_clauses).to eq([])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([])
      end
    end
  end
end
