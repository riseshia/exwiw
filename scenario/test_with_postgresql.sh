#!/bin/bash

set -e

export FROM_DATABASE_NAME="exwiw_scenario_prod_db"
export TO_DATABASE_NAME="exwiw_scenario_dev_db"

# Determine PostgreSQL command based on environment
if [ -n "$CI" ]; then
  # CI environment: use psql directly
  export PGPASSWORD="test_password"
  PSQL_CMD="psql -h 127.0.0.1 -p 5432 -U postgres"
  PSQL_FILE_CMD="psql -h 127.0.0.1 -p 5432 -U postgres"
else
  # Local environment: use docker compose exec
  PSQL_CMD="docker compose exec postgres psql -U postgres"
  PSQL_FILE_CMD="docker compose exec postgres psql -U postgres"
fi

# Clean up
$PSQL_CMD -c "DROP DATABASE IF EXISTS ${FROM_DATABASE_NAME}" > /dev/null
$PSQL_CMD -c "CREATE DATABASE ${FROM_DATABASE_NAME}" > /dev/null
$PSQL_CMD -c "DROP DATABASE IF EXISTS ${TO_DATABASE_NAME}" > /dev/null
$PSQL_CMD -c "CREATE DATABASE ${TO_DATABASE_NAME}" > /dev/null

# Setup db
if [ -n "$CI" ]; then
  $PSQL_FILE_CMD -d "${FROM_DATABASE_NAME}" -f seed/postgresql-dump.sql > /dev/null
  $PSQL_FILE_CMD -d "${TO_DATABASE_NAME}" -f seed/postgresql-dump.sql > /dev/null
else
  docker compose exec postgres psql -U postgres -d "${FROM_DATABASE_NAME}" -f /seed/postgresql-dump.sql > /dev/null
  docker compose exec postgres psql -U postgres -d "${TO_DATABASE_NAME}" -f /seed/postgresql-dump.sql > /dev/null
fi

# run exwiw
export DATABASE_PASSWORD="test_password"
bundle exec exe/exwiw \
  --adapter=postgresql \
  --host=127.0.0.1 \
  --port=5432 \
  --user=postgres \
  --database="${FROM_DATABASE_NAME}" \
  --config-dir=scenario/postgresql-schema \
  --target-table=shops \
  --ids=1 \
  --output-dir=tmp/postgresql

# import to db
for file in tmp/postgresql/delete-*.sql; do
  echo "Run ${file}"
  if [ -n "$CI" ]; then
    $PSQL_FILE_CMD -d "${TO_DATABASE_NAME}" -f "${file}" > /dev/null
  else
    docker compose exec postgres psql -U postgres -d "${TO_DATABASE_NAME}" -f "/scenario/${file}" > /dev/null
  fi
done

for file in tmp/postgresql/insert-*.sql; do
  echo "Run ${file}"
  if [ -n "$CI" ]; then
    $PSQL_FILE_CMD -d "${TO_DATABASE_NAME}" -f "${file}" > /dev/null
  else
    docker compose exec postgres psql -U postgres -d "${TO_DATABASE_NAME}" -f "/scenario/${file}" > /dev/null
  fi
done
