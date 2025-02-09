# frozen_string_literal: true

module Exwiw
  module Adapter
    RSpec.describe Sqlite3Adapter do
      let(:connection_config) do
        ConnectionConfig.new(
          adapter: 'sqlite3',
          database_name: 'tmp/test.sqlite3',
          host: nil,
          port: nil,
          user: nil,
          password: nil,
        )
      end
      let(:adapter) { Sqlite3Adapter.new(connection_config) }

      let(:simple_query_ast) do
        QueryAst::Select.new.tap do |ast|
          ast.from("shops")
          ast.select(["id", "name", "created_at", "updated_at"])
          ast.where(
            QueryAst::WhereClause.new(
              column_name: "id",
              operator: :eq,
              value: 1,
            )
          )
        end
      end

      let(:simple_query_ast2) do
        QueryAst::Select.new.tap do |ast|
          ast.from("users")
          ast.select(["id", "shop_id"])
          ast.where(
            QueryAst::WhereClause.new(
              column_name: "shop_id",
              operator: :eq,
              value: 1,
            )
          )
        end
      end

      let(:join_query_ast) do
        QueryAst::Select.new.tap do |ast|
          ast.from("order_items")
          ast.select(["id", "order_id"])
          ast.join(
            QueryAst::JoinClause.new(
              foreign_key: "order_id",
              join_table_name: "orders",
              primary_key: "id",
              where_clauses: [
                QueryAst::WhereClause.new(
                  column_name: "shop_id",
                  operator: :eq,
                  value: 1,
                )
              ],
            )
          )
        end
      end

      describe "#compile_ast" do
        context "simple select query" do
          let(:sql) { adapter.compile_ast(simple_query_ast) }

          it "builds sql" do
            expect(sql).to eq("SELECT shops.id, shops.name, shops.created_at, shops.updated_at FROM shops WHERE shops.id = 1")
          end
        end

        context "simple select query2" do
          let(:sql) { adapter.compile_ast(simple_query_ast2) }

          it "builds sql" do
            expect(sql).to eq("SELECT users.id, users.shop_id FROM users WHERE users.shop_id = 1")
          end
        end

        context "select query with one join" do
          let(:sql) { adapter.compile_ast(join_query_ast) }

          it "builds sql" do
            expect(sql).to eq(
              "SELECT order_items.id, order_items.order_id FROM order_items JOIN orders ON order_items.order_id = orders.id AND orders.shop_id = 1"
            )
          end
        end
      end

      describe "#execute" do
        context "simple select query" do
          let(:results) { adapter.execute(simple_query_ast) }

          it "returns correct results" do
            expect(results).to eq([
              [1, "Shop 1", "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
            ])
          end
        end

        context "simple select query2" do
          let(:results) { adapter.execute(simple_query_ast2) }

          it "returns correct results" do
            expect(results).to eq([
              [1, 1],
              [2, 1],
            ])
          end
        end

        context "select query with one join" do
          let(:results) { adapter.execute(join_query_ast) }

          it "returns correct results" do
            expect(results).to eq([
              [1, 1],
              [2, 2],
              [3, 3],
              [4, 4],
              [5, 5],
              [6, 6],
            ])
          end
        end
      end

      describe "#to_bulk_insert" do
        let(:results) do
          [
            [1, "Shop 1", "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
            [2, "Shop 2", "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
            [3, "Shop 3", "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
          ]
        end

        let(:table_name) { "shops" }

        let(:bulk_insert_sql) { adapter.to_bulk_insert(results, table_name) }

        it "returns correct bulk insert sql" do
          expect(bulk_insert_sql.strip).to eq(<<~SQL.strip)
            INSERT INTO shops VALUES
            (1, 'Shop 1', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
            (2, 'Shop 2', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
            (3, 'Shop 3', '2025-01-01 00:00:00', '2025-01-01 00:00:00');
          SQL
        end
      end
    end
  end
end
