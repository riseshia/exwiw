# frozen_string_literal: true

module Exwiw
  module Adapter
    RSpec.describe Sqlite3Adapter do
      let(:adapter_name) { 'sqlite3' }
      let(:connection_config) do
        ConnectionConfig.new(
          adapter: adapter_name,
          database_name: 'tmp/test.sqlite3',
          host: nil,
          port: nil,
          user: nil,
          password: nil,
        )
      end
      let(:logger) { Logger.new(nil) }
      let(:adapter) { described_class.new(connection_config, logger) }

      let(:simple_query_ast) do
        shops_table = shops_table(adapter_name)

        QueryAst::Select.new.tap do |ast|
          ast.from(shops_table.name)
          ast.select(shops_table.columns)
          ast.where(
            QueryAst::WhereClause.new(
              column_name: "id",
              operator: :eq,
              value: [1],
            )
          )
        end
      end

      let(:masking_query_ast) do
        users_table = users_table(adapter_name)

        QueryAst::Select.new.tap do |ast|
          ast.from(users_table.name)
          ast.select(users_table.columns)
          ast.where(
            QueryAst::WhereClause.new(
              column_name: "shop_id",
              operator: :eq,
              value: [1],
            )
          )
        end
      end

      let(:join_query_ast) do
        order_items_table = order_items_table(adapter_name)

        QueryAst::Select.new.tap do |ast|
          ast.from(order_items_table.name)
          ast.select(order_items_table.columns)
          ast.join(
            QueryAst::JoinClause.new(
              base_table_name: "order_items",
              foreign_key: "order_id",
              join_table_name: "orders",
              primary_key: "id",
              where_clauses: [
                QueryAst::WhereClause.new(
                  column_name: "shop_id",
                  operator: :eq,
                  value: [1],
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
            expect(sql).to eq("SELECT shops.id, shops.name, shops.updated_at, shops.created_at FROM shops WHERE shops.id = 1")
          end
        end

        context "select query with masking" do
          let(:sql) { adapter.compile_ast(masking_query_ast) }

          it "builds sql" do
            expect(sql).to eq("SELECT users.id, ('masked' || users.id), ('masked' || users.id || '@example.com'), users.shop_id, users.updated_at, users.created_at FROM users WHERE users.shop_id = 1")
          end
        end

        context "select query with one join" do
          let(:sql) { adapter.compile_ast(join_query_ast) }

          it "builds sql" do
            expect(sql).to eq(
              "SELECT order_items.id, order_items.quantity, order_items.order_id, order_items.product_id, order_items.updated_at, order_items.created_at FROM order_items JOIN orders ON order_items.order_id = orders.id AND orders.shop_id = 1"
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

        context "masking select query" do
          let(:results) { adapter.execute(masking_query_ast) }

          it "returns correct results" do
            expect(results).to eq([
              [1, "masked1", "masked1@example.com", 1, "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
              [2, "masked2", "masked2@example.com", 1, "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
            ])
          end
        end

        context "select query with one join" do
          let(:results) { adapter.execute(join_query_ast) }

          it "returns correct results" do
            expect(results).to eq([
              [1, 1, 1, 1, "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
              [2, 1, 2, 2, "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
              [3, 1, 3, 3, "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
              [4, 1, 4, 1, "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
              [5, 1, 5, 2, "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
              [6, 1, 6, 3, "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
            ])
          end
        end
      end

      describe "#to_bulk_insert" do
        context "simple select query" do
          let(:sql) { adapter.compile_ast(simple_query_ast) }

          it "builds sql" do
            expect(sql).to eq("SELECT shops.id, shops.name, shops.updated_at, shops.created_at FROM shops WHERE shops.id = 1")
          end
        end

        context "select query with masking" do
          let(:sql) { adapter.compile_ast(masking_query_ast) }

          it "builds sql" do
            expect(sql).to eq("SELECT users.id, ('masked' || users.id), ('masked' || users.id || '@example.com'), users.shop_id, users.updated_at, users.created_at FROM users WHERE users.shop_id = 1")
          end
        end

        context "select query with one join" do
          let(:sql) { adapter.compile_ast(join_query_ast) }

          it "builds sql" do
            expect(sql).to eq(
              "SELECT order_items.id, order_items.quantity, order_items.order_id, order_items.product_id, order_items.updated_at, order_items.created_at FROM order_items JOIN orders ON order_items.order_id = orders.id AND orders.shop_id = 1"
            )
          end
        end
        let(:results) do
          [
            [1, "Shop 1", "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
            [2, "Shop 2", "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
            [3, "Shop 3", "2025-01-01 00:00:00", "2025-01-01 00:00:00"],
          ]
        end

        let(:bulk_insert_sql) { adapter.to_bulk_insert(results, shops_table(adapter_name)) }

        it "returns correct bulk insert sql" do
          expect(bulk_insert_sql.strip).to eq(<<~SQL.strip)
            INSERT INTO shops (id, name, updated_at, created_at) VALUES
            (1, 'Shop 1', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
            (2, 'Shop 2', '2025-01-01 00:00:00', '2025-01-01 00:00:00'),
            (3, 'Shop 3', '2025-01-01 00:00:00', '2025-01-01 00:00:00');
          SQL
        end
      end

      describe "#to_bulk_delete" do
        context "simple select query" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(simple_query_ast, shops_table(adapter_name)) }

          it "builds sql" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM shops
              WHERE shops.id = 1;
            SQL
          end
        end

        context "select query with masking" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(masking_query_ast, users_table(adapter_name)) }

          it "builds sql" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM users
              WHERE users.shop_id = 1;
            SQL
          end
        end

        context "select query with one join" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(join_query_ast, order_items_table(adapter_name)) }

          it "builds sql" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM order_items
              WHERE order_items.order_id IN (SELECT orders.id FROM orders WHERE orders.shop_id = 1);
            SQL
          end
        end
      end
    end
  end
end
