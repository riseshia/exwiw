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
    let(:built_query_ast) { described_class.run(table.name, all_tables, dump_target) }

    context 'when the table is same as dump target table' do
      let(:table) { shops_table }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('shops')
        expect(built_query_ast.column_names).to eq(['id', 'name', 'created_at', 'updated_at'])
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
        expect(built_query_ast.column_names).to eq(['id', 'name', 'email', 'shop_id', 'created_at', 'updated_at'])
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
        expect(built_query_ast.column_names).to eq(['id', 'quantity', 'order_id', 'product_id', 'created_at', 'updated_at'])
        expect(built_query_ast.join_clauses.map(&:to_h)).to eq([
          { foreign_key: 'order_id', join_table_name: 'orders', primary_key: 'id' },
          { foreign_key: 'shop_id', join_table_name: 'shops', primary_key: 'id', where_clauses: [{ column_name: 'id', operator: :eq, value: [1] }] },
        ])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([])
      end
    end

    context 'when the table is indirect relation with dump target table' do
      let(:table) { transactions_table }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('transactions')
        expect(built_query_ast.column_names).to eq(['id', 'type', 'amount', 'order_id', 'created_at', 'updated_at'])
        expect(built_query_ast.join_clauses.map(&:to_h)).to eq([
          { foreign_key: 'order_id', join_table_name: 'orders', primary_key: 'id' },
          { foreign_key: 'shop_id', join_table_name: 'shops', primary_key: 'id', where_clauses: [{ column_name: 'id', operator: :eq, value: [1] }] },
        ])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([])
      end
    end

    context 'when the table has no relation with dump target table' do
      let(:table) { system_announcements_table }

      it 'builds correct query ast' do
        expect(built_query_ast.from_table_name).to eq('system_announcements')
        expect(built_query_ast.column_names).to eq(['id', 'title', 'content', 'created_at', 'updated_at'])
        expect(built_query_ast.join_clauses).to eq([])
        expect(built_query_ast.where_clauses.map(&:to_h)).to eq([])
      end
    end
  end
end
