# frozen_string_literal: true

module Exwiw
  module Adapter
    RSpec.describe MongodbAdapter do
      let(:adapter_name) { 'mongodb' }
      let(:connection_config) do
        ConnectionConfig.new(
          adapter: adapter_name,
          database_name: 'exwiw_test',
          host: ENV.fetch('MONGO_HOST', '127.0.0.1'),
          port: ENV.fetch('MONGO_PORT', 27017).to_i,
          user: nil,
          password: nil,
        )
      end
      let(:logger) { Logger.new(nil) }
      let(:adapter) { described_class.new(connection_config, logger) }

      let(:table_by_name) do
        %w[shops users products orders order_items transactions system_announcements]
          .map { |n| send("#{n}_table", adapter_name) }
          .each_with_object({}) { |t, h| h[t.name] = t }
      end

      describe "#build_query" do
        context "for the dump_target table itself" do
          let(:dump_target) { Exwiw::DumpTarget.new(table_name: "shops", ids: [1]) }

          it "filters by primary_key with $in" do
            shops = table_by_name.fetch("shops")
            query = adapter.build_query(shops, dump_target, table_by_name)
            expect(query.to_h).to eq(
              collection: "shops",
              primary_key: "_id",
              filter: { "_id" => { "$in" => [1] } },
              projection: { "_id" => 1, "name" => 1, "updated_at" => 1, "created_at" => 1 },
            )
          end
        end

        context "for a related table with no upstream state" do
          let(:dump_target) { Exwiw::DumpTarget.new(table_name: "shops", ids: [1]) }

          it "uses an empty filter (extracts everything)" do
            users = table_by_name.fetch("users")
            query = adapter.build_query(users, dump_target, table_by_name)
            expect(query.filter).to eq({})
            expect(query.collection).to eq("users")
            expect(query.primary_key).to eq("_id")
          end
        end

        context "for a related table after upstream state is populated" do
          let(:dump_target) { Exwiw::DumpTarget.new(table_name: "shops", ids: [1]) }

          it "filters by foreign_key with $in using state from previous execute" do
            shops = table_by_name.fetch("shops")
            users = table_by_name.fetch("users")

            shops_query = adapter.build_query(shops, dump_target, table_by_name)
            adapter.execute(shops_query)

            users_query = adapter.build_query(users, dump_target, table_by_name)
            expect(users_query.filter).to eq("shop_id" => { "$in" => [1] })
          end
        end

        context "for a table with raw_sql column" do
          let(:dump_target) { Exwiw::DumpTarget.new(table_name: "shops", ids: [1]) }
          let(:bad_table) do
            Exwiw::TableConfig.from_hash(
              "name" => "bad",
              "primary_key" => "_id",
              "belongs_tos" => [],
              "columns" => [
                { "name" => "_id" },
                { "name" => "raw", "raw_sql" => "CONCAT('a', 'b')" },
              ],
            )
          end

          it "raises NotImplementedError" do
            expect { adapter.build_query(bad_table, dump_target, table_by_name) }.to raise_error(NotImplementedError)
          end
        end
      end

      describe "#execute" do
        context "for the dump_target table" do
          let(:dump_target) { Exwiw::DumpTarget.new(table_name: "shops", ids: [1]) }

          it "returns matching documents" do
            shops = table_by_name.fetch("shops")
            query = adapter.build_query(shops, dump_target, table_by_name)
            results = adapter.execute(query)
            expect(results.size).to eq(1)
            expect(results.first["_id"]).to eq(1)
            expect(results.first["name"]).to eq("Shop 1")
          end
        end

        context "for a related table after running the dump_target table" do
          let(:dump_target) { Exwiw::DumpTarget.new(table_name: "shops", ids: [1]) }

          it "limits results via state-driven $in filter" do
            shops = table_by_name.fetch("shops")
            users_t = table_by_name.fetch("users")

            adapter.execute(adapter.build_query(shops, dump_target, table_by_name))
            users = adapter.execute(adapter.build_query(users_t, dump_target, table_by_name))

            expect(users.size).to eq(2)
            expect(users.map { |u| u["shop_id"] }.uniq).to eq([1])
          end
        end
      end

      describe "#to_bulk_insert" do
        it "applies replace_with templates and emits JSONL" do
          users_t = table_by_name.fetch("users")
          rows = [
            { "_id" => 1, "name" => "User 1", "email" => "user1@example.com", "shop_id" => 1 },
            { "_id" => 2, "name" => "User 2", "email" => "user2@example.com", "shop_id" => 1 },
          ]
          jsonl = adapter.to_bulk_insert(rows, users_t)
          lines = jsonl.split("\n")
          parsed = lines.map { |l| JSON.parse(l) }

          expect(parsed[0]["name"]).to eq("masked1")
          expect(parsed[0]["email"]).to eq("masked1@example.com")
          expect(parsed[1]["name"]).to eq("masked2")
          expect(parsed[1]["email"]).to eq("masked2@example.com")
        end
      end

      describe "#to_bulk_delete" do
        let(:dump_target) { Exwiw::DumpTarget.new(table_name: "shops", ids: [1]) }

        it "raises NotImplementedError" do
          shops = table_by_name.fetch("shops")
          query = adapter.build_query(shops, dump_target, table_by_name)
          expect { adapter.to_bulk_delete(query, shops) }.to raise_error(NotImplementedError)
        end
      end

      describe "#output_extension" do
        it { expect(adapter.output_extension).to eq("jsonl") }
      end

      describe "#supports_bulk_delete?" do
        it { expect(adapter.supports_bulk_delete?).to eq(false) }
      end
    end
  end
end
