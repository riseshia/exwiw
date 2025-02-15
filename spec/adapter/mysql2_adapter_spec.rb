# frozen_string_literal: true

module Exwiw
  module Adapter
    RSpec.describe Mysql2Adapter do
      let(:adapter_name) { 'mysql2' }
      let(:connection_config) do
        ConnectionConfig.new(
          adapter: adapter_name,
          database_name: 'exwiw_test',
          host: '127.0.0.1',
          port: 3306,
          user: 'root',
          password: 'rootpassword',
        )
      end
      let(:logger) { Logger.new(nil) }
      let(:adapter) { described_class.new(connection_config, logger) }

      describe "#compile_ast" do
        context "simple select query" do
          let(:sql) { adapter.compile_ast(build_select_shops_ast) }

          it "builds sql" do
            expect(sql).to eq("SELECT shops.id, shops.name, shops.updated_at, shops.created_at FROM shops WHERE shops.id = 1")
          end
        end

        context "select query with masking" do
          let(:sql) { adapter.compile_ast(build_select_users_ast) }

          it "builds sql" do
            expect(sql).to eq("SELECT users.id, CONCAT('masked', users.id), CONCAT('masked', users.id, '@example.com'), users.shop_id, users.updated_at, users.created_at FROM users WHERE users.shop_id = 1")
          end
        end

        context "select query with filter" do
          let(:sql) { adapter.compile_ast(build_select_users_ast("users.id > 1")) }

          it "builds sql" do
            expect(sql).to eq("SELECT users.id, CONCAT('masked', users.id), CONCAT('masked', users.id, '@example.com'), users.shop_id, users.updated_at, users.created_at FROM users WHERE users.shop_id = 1 AND users.id > 1")
          end
        end

        context "select query with one join" do
          let(:sql) { adapter.compile_ast(build_order_items_ast) }

          it "builds sql" do
            expect(sql).to eq(
              "SELECT order_items.id, order_items.quantity, order_items.order_id, order_items.product_id, order_items.updated_at, order_items.created_at FROM order_items JOIN orders ON order_items.order_id = orders.id AND orders.shop_id = 1"
            )
          end
        end

        context "select query with one join, one filter" do
          let(:sql) { adapter.compile_ast(build_order_items_ast("order_items.id > 1", nil)) }

          it "builds sql" do
            expect(sql).to eq(
              "SELECT order_items.id, order_items.quantity, order_items.order_id, order_items.product_id, order_items.updated_at, order_items.created_at FROM order_items JOIN orders ON order_items.order_id = orders.id AND orders.shop_id = 1 WHERE order_items.id > 1"
            )
          end
        end

        context "select query with filter on join" do
          let(:sql) { adapter.compile_ast(build_order_items_ast(nil,  "orders.id > 1")) }

          it "builds sql" do
            expect(sql).to eq(
              "SELECT order_items.id, order_items.quantity, order_items.order_id, order_items.product_id, order_items.updated_at, order_items.created_at FROM order_items JOIN orders ON order_items.order_id = orders.id AND orders.shop_id = 1 AND orders.id > 1"
            )
          end
        end

        context "select query with filter on join and filter on where" do
          let(:sql) { adapter.compile_ast(build_order_items_ast("order_items.id > 3",  "orders.id > 1")) }

          it "builds sql" do
            expect(sql).to eq(
              "SELECT order_items.id, order_items.quantity, order_items.order_id, order_items.product_id, order_items.updated_at, order_items.created_at FROM order_items JOIN orders ON order_items.order_id = orders.id AND orders.shop_id = 1 AND orders.id > 1 WHERE order_items.id > 3"
            )
          end
        end
      end

      describe "#execute" do
        context "simple select query" do
          let(:results) { adapter.execute(build_select_shops_ast) }

          it "returns correct results" do
            skip if ENV["CI"]

            expect(results).to eq([
              ["1", "Shop 1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ])
          end
        end

        context "select query with masking" do
          let(:results) { adapter.execute(build_select_users_ast) }

          it "returns correct results" do
            skip if ENV["CI"]

            expect(results).to eq([
              ["1", "masked1", "masked1@example.com", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["2", "masked2", "masked2@example.com", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ])
          end
        end

        context "select query with filter" do
          let(:results) { adapter.execute(build_select_users_ast("users.id > 1")) }

          it "returns correct results" do
            skip if ENV["CI"]

            expect(results).to eq([
              ["2", "masked2", "masked2@example.com", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ])
          end
        end

        context "select query with one join" do
          let(:results) { adapter.execute(build_order_items_ast) }

          it "returns correct results" do
            skip if ENV["CI"]

            expect(results).to eq([
              ["1", "1", "1", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["2", "1", "2", "2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["3", "1", "3", "3", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["4", "1", "4", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["5", "1", "5", "2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["6", "1", "6", "3", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ])
          end
        end

        context "select query with one join, one filter" do
          let(:results) { adapter.execute(build_order_items_ast("order_items.id > 1", nil)) }

          it "returns correct results" do
            skip if ENV["CI"]

            expect(results.to_a).to eq([
              ["2", "1", "2", "2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["3", "1", "3", "3", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["4", "1", "4", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["5", "1", "5", "2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["6", "1", "6", "3", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ])
          end
        end

        context "select query with filter on join" do
          let(:results) { adapter.execute(build_order_items_ast(nil, "orders.id < 6")) }

          it "returns correct results" do
            skip if ENV["CI"]

            expect(results).to eq([
              ["1", "1", "1", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["2", "1", "2", "2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["3", "1", "3", "3", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["4", "1", "4", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["5", "1", "5", "2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ])
          end
        end

        context "select query with filter on join and filter on where" do
          let(:results) { adapter.execute(build_order_items_ast("order_items.id > 1", "orders.id < 6")) }

          it "returns correct results" do
            skip if ENV["CI"]

            expect(results).to eq([
              ["2", "1", "2", "2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["3", "1", "3", "3", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["4", "1", "4", "1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["5", "1", "5", "2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ])
          end
        end
      end

      describe "#to_bulk_insert" do
        let(:bulk_insert_sql) { adapter.to_bulk_insert(results, shops_table(adapter_name)) }

        context "simple select query" do
          let(:results) do
            [
              ["1", "Shop 1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["2", "Shop 2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["3", "Shop 3", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ]
          end

          let(:bulk_insert_sql) { adapter.to_bulk_insert(results, shops_table(adapter_name)) }

          it "returns correct bulk insert sql" do
            expect(bulk_insert_sql.strip).to eq(<<~SQL.strip)
              INSERT INTO shops (id, name, updated_at, created_at) VALUES
              ('1', 'Shop 1', '2025-01-01 00:00:00.000000', '2025-01-01 00:00:00.000000'),
              ('2', 'Shop 2', '2025-01-01 00:00:00.000000', '2025-01-01 00:00:00.000000'),
              ('3', 'Shop 3', '2025-01-01 00:00:00.000000', '2025-01-01 00:00:00.000000');
            SQL
          end
        end

        context "has single quote" do
          let(:results) do
            [
              ["1", "Shop' 1", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["2", "Shop 2", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
              ["3", "Shop 3", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"],
            ]
          end

          let(:bulk_insert_sql) { adapter.to_bulk_insert(results, shops_table(adapter_name)) }

          it "returns correct bulk insert sql" do
            expect(bulk_insert_sql.strip).to eq(<<~SQL.strip)
              INSERT INTO shops (id, name, updated_at, created_at) VALUES
              ('1', 'Shop'' 1', '2025-01-01 00:00:00.000000', '2025-01-01 00:00:00.000000'),
              ('2', 'Shop 2', '2025-01-01 00:00:00.000000', '2025-01-01 00:00:00.000000'),
              ('3', 'Shop 3', '2025-01-01 00:00:00.000000', '2025-01-01 00:00:00.000000');
            SQL
          end
        end
      end

      describe "#to_bulk_delete" do
        context "simple select query" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(build_select_shops_ast, shops_table(adapter_name)) }

          it "builds sql" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM shops
              WHERE shops.id = 1;
            SQL
          end
        end

        context "select query with masking" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(build_select_users_ast, users_table(adapter_name)) }

          it "builds sql" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM users
              WHERE users.shop_id = 1;
            SQL
          end
        end

        context "select query with filter" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(build_select_users_ast("users.id > 1"), users_table(adapter_name)) }

          it "ignores filter option" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM users
              WHERE users.shop_id = 1;
            SQL
          end
        end

        context "select query with one join" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(build_order_items_ast, order_items_table(adapter_name)) }

          it "ignores filter option" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM order_items
              WHERE order_items.order_id IN (SELECT orders.id FROM orders WHERE orders.shop_id = 1);
            SQL
          end
        end

        context "select query with one join, one filter" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(build_order_items_ast("order_items.id > 1", nil), order_items_table(adapter_name)) }

          it "ignores filter option" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM order_items
              WHERE order_items.order_id IN (SELECT orders.id FROM orders WHERE orders.shop_id = 1);
            SQL
          end
        end

        context "select query with filter on join" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(build_order_items_ast(nil, "orders.id > 1"), order_items_table(adapter_name)) }

          it "ignores filter option" do
            expect(bulk_delete_sql.strip).to eq(<<~SQL.strip)
              DELETE FROM order_items
              WHERE order_items.order_id IN (SELECT orders.id FROM orders WHERE orders.shop_id = 1);
            SQL
          end
        end

        context "select query with filter on join and filter on where" do
          let(:bulk_delete_sql) { adapter.to_bulk_delete(build_order_items_ast("order_items.id > 1", "orders.id > 1"), order_items_table(adapter_name)) }

          it "ignores filter option" do
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
