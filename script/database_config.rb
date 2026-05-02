DATABASE_CONFIGS = {
  sqlite3: {
    adapter: "sqlite3",
    database: ENV.fetch("DATABASE_NAME", "tmp/test.sqlite3"),
  },
  mysql2: {
    adapter: "mysql2",
    host: ENV.fetch("MYSQL_HOST", "127.0.0.1"),
    port: ENV.fetch("MYSQL_PORT", 3306),
    database: ENV.fetch("DATABASE_NAME", "exwiw_test"),
    username: ENV.fetch("MYSQL_USERNAME", "root"),
    password: ENV.fetch("MYSQL_PASSWORD", "rootpassword"),
  },
  postgresql: {
    adapter: "postgresql",
    host: ENV.fetch("POSTGRES_HOST", "127.0.0.1"),
    port: ENV.fetch("POSTGRES_PORT", 5432),
    database: ENV.fetch("DATABASE_NAME", "exwiw_test"),
    username: ENV.fetch("POSTGRES_USERNAME", "postgres"),
    password: ENV.fetch("POSTGRES_PASSWORD", "test_password"),
  },
  mongodb: {
    adapter: "mongodb",
    host: ENV.fetch("MONGO_HOST", "127.0.0.1"),
    port: ENV.fetch("MONGO_PORT", 27017),
    database: ENV.fetch("DATABASE_NAME", "exwiw_test"),
  },
}

def database_config(adapter)
  DATABASE_CONFIGS.fetch(adapter.to_sym)
end
