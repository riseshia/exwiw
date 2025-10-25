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

      describe "import and insert" do
        let(:import_db_name) { 'exwiw_test_import' }
        let(:import_connection_config) do
          ConnectionConfig.new(
            adapter: adapter_name,
            database_name: import_db_name,
            host: '127.0.0.1',
            port: 3306,
            user: 'root',
            password: 'rootpassword',
          )
        end
        let(:import_adapter) { described_class.new(import_connection_config, logger) }

        before do
          skip if ENV["CI"]

          # Create a fresh empty database with schema
          conn = Mysql2::Client.new(
            host: '127.0.0.1',
            port: 3306,
            username: 'root',
            password: 'rootpassword',
          )

          conn.query("DROP DATABASE IF EXISTS #{import_db_name}")
          conn.query("CREATE DATABASE #{import_db_name}")
          conn.close

          conn = Mysql2::Client.new(
            host: '127.0.0.1',
            port: 3306,
            username: 'root',
            password: 'rootpassword',
            database: import_db_name,
          )

          # Create shops table
          conn.query(<<~SQL)
            CREATE TABLE shops (
              id INT PRIMARY KEY,
              name VARCHAR(255) NOT NULL,
              updated_at DATETIME(6) NOT NULL,
              created_at DATETIME(6) NOT NULL
            )
          SQL

          # Create users table
          conn.query(<<~SQL)
            CREATE TABLE users (
              id INT PRIMARY KEY,
              name VARCHAR(255) NOT NULL,
              email VARCHAR(255) NOT NULL,
              shop_id INT NOT NULL,
              updated_at DATETIME(6) NOT NULL,
              created_at DATETIME(6) NOT NULL
            )
          SQL

          conn.close
        end

        after do
          skip if ENV["CI"]

          conn = Mysql2::Client.new(
            host: '127.0.0.1',
            port: 3306,
            username: 'root',
            password: 'rootpassword',
          )
          conn.query("DROP DATABASE IF EXISTS #{import_db_name}")
          conn.close
        end

        context "importing shops data" do
          it "can insert exported data and query it back" do
            skip if ENV["CI"]

            # Export data from source database
            results = adapter.execute(build_select_shops_ast)
            expect(results).not_to be_empty

            # Generate INSERT SQL
            insert_sql = adapter.to_bulk_insert(results, shops_table(adapter_name))

            # Import into new database
            conn = Mysql2::Client.new(
              host: '127.0.0.1',
              port: 3306,
              username: 'root',
              password: 'rootpassword',
              database: import_db_name,
            )
            conn.query(insert_sql)
            conn.close

            # Verify data was inserted
            imported_results = import_adapter.execute(build_select_shops_ast)
            expect(imported_results).to eq(results)
          end
        end

        context "importing users data with masking" do
          it "can insert exported masked data and query it back" do
            skip if ENV["CI"]

            # Export data from source database (with masking applied)
            results = adapter.execute(build_select_users_ast)
            expect(results).not_to be_empty

            # Generate INSERT SQL
            insert_sql = adapter.to_bulk_insert(results, users_table(adapter_name))

            # Import into new database
            conn = Mysql2::Client.new(
              host: '127.0.0.1',
              port: 3306,
              username: 'root',
              password: 'rootpassword',
              database: import_db_name,
            )
            conn.query(insert_sql)
            conn.close

            # Verify data was inserted
            imported_results = import_adapter.execute(build_select_users_ast)
            expect(imported_results).to eq(results)

            # Verify masking was applied (names should be masked)
            expect(imported_results.first[1]).to eq("masked1")
            expect(imported_results.first[2]).to eq("masked1@example.com")
          end
        end

        context "importing data with special characters" do
          it "can insert data with single quotes" do
            skip if ENV["CI"]

            # Create test data with single quote
            results = [
              ["999", "Shop's Name", "2025-01-01 00:00:00.000000", "2025-01-01 00:00:00.000000"]
            ]

            # Generate INSERT SQL
            insert_sql = adapter.to_bulk_insert(results, shops_table(adapter_name))

            # Import into new database
            conn = Mysql2::Client.new(
              host: '127.0.0.1',
              port: 3306,
              username: 'root',
              password: 'rootpassword',
              database: import_db_name,
            )
            conn.query(insert_sql)
            conn.close

            # Verify data was inserted correctly with single quote preserved
            conn = Mysql2::Client.new(
              host: '127.0.0.1',
              port: 3306,
              username: 'root',
              password: 'rootpassword',
              database: import_db_name,
            )
            query_results = conn.query("SELECT * FROM shops WHERE id = 999").to_a
            conn.close

            expect(query_results.first["id"]).to eq(999)
            expect(query_results.first["name"]).to eq("Shop's Name")
          end
        end
      end
    end
  end
end
