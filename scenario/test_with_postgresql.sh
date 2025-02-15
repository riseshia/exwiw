#!/bin/bash

set -e

export FROM_DATABASE_NAME="exwiw_scenario_prod_db"
export TO_DATABASE_NAME="exwiw_scenario_dev_db"

# Clean up
docker compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS ${FROM_DATABASE_NAME}" > /dev/null
docker compose exec postgres psql -U postgres -c "CREATE DATABASE ${FROM_DATABASE_NAME}" > /dev/null
docker compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS ${TO_DATABASE_NAME}" > /dev/null
docker compose exec postgres psql -U postgres -c "CREATE DATABASE ${TO_DATABASE_NAME}" > /dev/null

# Setup db
docker compose exec postgres psql -U postgres -d "${FROM_DATABASE_NAME}" -f /seed/postgresql-dump.sql > /dev/null
docker compose exec postgres psql -U postgres -d "${TO_DATABASE_NAME}" -f /seed/postgresql-dump.sql > /dev/null

# run exwiw
export DATABASE_PASSWORD="test_password"
bundle exec exe/exwiw \
  --adapter=postgresql \
  --host=127.0.0.1 \
  --port=5432 \
  --user=postgres \
  --database="${FROM_DATABASE_NAME}" \
  --config-dir=scenario/schema \
  --target-table=shops \
  --ids=1 \
  --output-dir=tmp/postgresql

# import to db
for file in tmp/postgresql/delete-*.sql; do
  echo "Run ${file}"
  docker compose exec postgres psql -U postgres -d "${TO_DATABASE_NAME}" -f "/scenario/${file}" > /dev/null
done

for file in tmp/postgresql/insert-*.sql; do
  echo "Run ${file}"
  docker compose exec postgres psql -U postgres -d "${TO_DATABASE_NAME}" -f "/scenario/${file}" > /dev/null
done
