# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Exwiw::DetermineTableProcessingOrder do
  describe '.run' do
    let(:target_table_name) { 'shops' }
    let(:target_ids) { [1] }

    let(:sorted_table_names) { described_class.run(tables) }


    context 'when there are only shops' do
      let(:tables) do
        [shops_table(:sqlite3)]
      end

      it 'returns shops' do
        expect(sorted_table_names).to eq(['shops'])
      end
    end

    context 'when there are independent' do
      let(:tables) do
        [
          system_announcements_table(:sqlite3),
          shops_table(:sqlite3),
        ]
      end

      it 'returns ordered names' do
        expect(sorted_table_names).to eq(['system_announcements', 'shops'])
      end
    end

    context 'when there are just belongs_to' do
      let(:tables) do
        [
          orders_table(:sqlite3),
          users_table(:sqlite3),
          products_table(:sqlite3),
          system_announcements_table(:sqlite3),
          shops_table(:sqlite3),
        ]
      end

      it 'returns ordered names' do
        expect(sorted_table_names).to eq([
          'system_announcements',
          'shops',
          'users',
          'products',
          'orders',
        ])
      end
    end

    context 'when there are belongs_to, n:m' do
      let(:tables) do
        [
          order_items_table(:sqlite3),
          orders_table(:sqlite3),
          users_table(:sqlite3),
          products_table(:sqlite3),
          shops_table(:sqlite3),
        ]
      end

      it 'returns ordered names' do
        expect(sorted_table_names).to eq([
          'shops',
          'users',
          'products',
          'orders',
          'order_items',
        ])
      end
    end

    context 'when there is polymorphic' do
      let(:tables) do
        [
          users_table(:sqlite3),
          products_table(:sqlite3),
          reviews_table(:sqlite3),
          shops_table(:sqlite3),
        ]
      end

      it 'returns ordered names' do
        skip 'support polymorphic'
        expect(sorted_table_names).to eq([
          'shops',
          'users',
          'products',
          'reviews',
        ])
      end
    end

    context 'when there is sti' do
      let(:tables) do
        [
          transactions_table(:sqlite3),
          orders_table(:sqlite3),
          users_table(:sqlite3),
          products_table(:sqlite3),
          shops_table(:sqlite3),
        ]
      end

      it 'returns ordered names' do
        expect(sorted_table_names).to eq([
          'shops',
          'users',
          'products',
          'orders',
          'transactions',
        ])
      end
    end

    context 'when full tables' do
      let(:tables) do
        [
          order_items_table(:sqlite3),
          transactions_table(:sqlite3),
          orders_table(:sqlite3),
          users_table(:sqlite3),
          products_table(:sqlite3),
          system_announcements_table(:sqlite3),
          shops_table(:sqlite3),
        ]
      end

      it 'returns ordered names' do
        expect(sorted_table_names).to eq([
          'system_announcements',
          'shops',
          'users',
          'products',
          'orders',
          'order_items',
          'transactions',
        ])
      end
    end
  end
end
