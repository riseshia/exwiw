#!/bin/bash

## Sqlite3

export DATABASE_NAME="tmp/seed.sqlite3"
rm -f "${DATABASE_NAME}"

bundle exec ruby script/define_schema.rb "sqlite3"
sqlite3 tmp/seed.sqlite3 ".schema" > seed/sqlite3-schema.sql
bundle exec ruby script/generate_data.rb "sqlite3"
sqlite3 tmp/seed.sqlite3 ".dump" > seed/sqlite3-dump.sql

## MySQL

export DATABASE_NAME="exwiw_seed"

docker compose exec mysql mysql -u root -p'rootpassword' -e "DROP DATABASE IF EXISTS ${DATABASE_NAME}; CREATE DATABASE ${DATABASE_NAME};"

bundle exec ruby script/define_schema.rb "mysql2"
docker compose exec mysql mysqldump -u root -p'rootpassword' \
  --no-data "${DATABASE_NAME}" > seed/mysql2-schema.sql
bundle exec ruby script/generate_data.rb "mysql2"
docker compose exec mysql mysqldump -u root -p'rootpassword' \
 "${DATABASE_NAME}" > seed/mysql2-dump.sql

## PostgreSQL

export DATABASE_NAME="exwiw_seed"

docker compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS ${DATABASE_NAME}"
docker compose exec postgres psql -U postgres -c "CREATE DATABASE ${DATABASE_NAME}"

bundle exec ruby script/define_schema.rb "postgresql"
docker compose exec postgres pg_dump -U postgres -d "${DATABASE_NAME}" --schema-only > seed/postgresql-schema.sql

bundle exec ruby script/generate_data.rb "postgresql"
docker compose exec postgres pg_dump -U postgres -d "${DATABASE_NAME}" > seed/postgresql-dump.sql
