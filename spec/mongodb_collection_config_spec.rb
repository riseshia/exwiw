require 'spec_helper'

module Exwiw
  RSpec.describe MongodbCollectionConfig do
    describe '.from' do
      let(:json) do
        {
          "name" => "users",
          "primary_key" => "_id",
          "belongs_tos" => [{ "table_name" => "shops", "foreign_key" => "shop_id" }],
          "fields" => [
            { "name" => "_id" },
            { "name" => "name", "replace_with" => "masked{_id}" },
            { "name" => "shop_id" },
          ],
        }
      end

      it 'loads a top-level collection config' do
        config = described_class.from(json)
        expect(config.name).to eq("users")
        expect(config.primary_key).to eq("_id")
        expect(config.belongs_tos.map(&:to_hash)).to eq([
          { "table_name" => "shops", "foreign_key" => "shop_id" },
        ])
        expect(config.fields.map(&:to_hash)).to eq([
          { "name" => "_id" },
          { "name" => "name", "replace_with" => "masked{_id}" },
          { "name" => "shop_id" },
        ])
      end

      context 'when fields contain raw_sql key' do
        let(:json) do
          {
            "name" => "users",
            "primary_key" => "_id",
            "belongs_tos" => [],
            "fields" => [
              { "name" => "raw", "raw_sql" => "CONCAT('a','b')" },
            ],
          }
        end

        it 'silently ignores raw_sql since MongodbField does not declare it' do
          config = described_class.from(json)
          expect(config.fields.first.to_hash).to eq({ "name" => "raw" })
        end
      end
    end

    describe '.from_symbol_keys' do
      it 'accepts symbol keys' do
        config = described_class.from_symbol_keys(
          name: "users",
          primary_key: "_id",
          belongs_tos: [],
          fields: [{ name: "_id" }],
        )
        expect(config.name).to eq("users")
        expect(config.fields.first.name).to eq("_id")
      end
    end
  end
end
