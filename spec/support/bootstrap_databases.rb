# frozen_string_literal: true

require "sqlite3"
require "mysql2"
require "pg"

require_relative "../../script/database_config"

module BootstrapDatabases
  module_function

  def run
    setup_sqlite3
    setup_mysql2
    setup_postgres
  end

  private def setup_sqlite3
    sqlite3_config = database_config("sqlite3")
    database_name = sqlite3_config.fetch(:database)
    File.delete(database_name) if File.exist?(database_name)

    conn = SQLite3::Database.new(database_name)
    sql = File.read("seed/sqlite3-dump.sql")
    conn.execute_batch(sql)
  end

  private def setup_mysql2
    mysql2_config = database_config("mysql2")
    database_name = mysql2_config.fetch(:database)
    username = mysql2_config.fetch(:username)

    conn = Mysql2::Client.new(mysql2_config.except(:database))
    conn.query("DROP DATABASE IF EXISTS #{database_name}")
    conn.query("CREATE DATABASE #{database_name}")

    system("docker compose exec -T mysql mysql -u #{username} #{database_name} < seed/mysql2-dump.sql")
  end

  private def setup_postgres
    postgres_config = database_config("postgresql")
    database_name = postgres_config.fetch(:database)

    conn = PG.connect(
      host: postgres_config.fetch(:host),
      port: postgres_config.fetch(:port),
      user: postgres_config.fetch(:username),
      password: postgres_config.fetch(:password),
    )

    conn.exec("DROP DATABASE IF EXISTS #{database_name}")
    conn.exec("CREATE DATABASE #{database_name}")

    system("docker compose exec postgres psql -U postgres -d '#{database_name}' -f seed/postgresql-dump.sql > /dev/null")
  end
end
