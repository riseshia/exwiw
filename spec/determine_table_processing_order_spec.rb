require 'spec_helper'

RSpec.describe Exwiw::DetermineTableProcessingOrder do
  describe '.run' do
    let(:target_table_name) { 'shops' }
    let(:target_ids) { [1] }

    let(:sorted_table_names) { described_class.run(tables) }

    context 'when there are only shops' do
      let(:tables) do
        [
          Exwiw::Table.from_symbol_keys({
            name: 'shops',
            primary_key: 'id',
            belongs_to_relations: [],
            polymorphic_as: [],
            columns: [
              Exwiw::TableColumn.from_symbol_keys({ name: 'id', type: 'integer' })
            ]
          })
        ]
      end

      it 'returns shops' do
        expect(sorted_table_names).to eq(['shops'])
      end
    end
  end
end
