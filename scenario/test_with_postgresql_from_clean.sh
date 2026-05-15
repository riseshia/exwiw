#!/bin/bash

# Variant of test_with_postgresql.sh that exercises the "fresh target DB" path.
# The TO database is created empty (no schema, no rows), so the run must
# succeed purely on the strength of insert-000-schema.sql creating the schema
# before subsequent insert-*.sql statements run.
#
# Unlike test_with_postgresql.sh, the delete-*.sql pass is skipped because the
# TO database has no tables to delete from.

set -e

export FROM_DATABASE_NAME="exwiw_scenario_prod_db"
export TO_DATABASE_NAME="exwiw_scenario_dev_clean_db"

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

# Seed only the FROM database. TO is left empty on purpose to validate that
# insert-000-schema.sql can stand up the schema from scratch.
if [ -n "$CI" ]; then
  $PSQL_FILE_CMD -d "${FROM_DATABASE_NAME}" -f seed/postgresql-dump.sql > /dev/null
else
  docker compose exec postgres psql -U postgres -d "${FROM_DATABASE_NAME}" -f /seed/postgresql-dump.sql > /dev/null
fi

# run exwiw — output to a dedicated dir so we don't collide with the other
# scenario's artifacts.
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
  --output-dir=tmp/postgresql-clean

# Apply insert-*.sql against the empty TO database. insert-000-schema.sql is
# expected to be the first file and to create every table referenced by the
# subsequent insert-*.sql statements.
for file in tmp/postgresql-clean/insert-*.sql; do
  echo "Run ${file}"
  if [ -n "$CI" ]; then
    $PSQL_FILE_CMD -d "${TO_DATABASE_NAME}" -f "${file}" > /dev/null
  else
    docker compose exec postgres psql -U postgres -d "${TO_DATABASE_NAME}" -f "/scenario/${file}" > /dev/null
  fi
done

# Verify that the schema was created and the target row landed.
# We intentionally do NOT exercise auto-increment here: exwiw currently
# doesn't emit `setval` for sequences, so on a freshly-created schema the
# sequence stays at its initial position while inserted rows already occupy
# those low IDs. That gap belongs to a follow-up on exwiw itself, not this
# scenario test.
echo "Verifying import to clean DB..."
COUNT=$($PSQL_CMD -d "${TO_DATABASE_NAME}" -t -c "SELECT COUNT(*) FROM shops WHERE id = 1;" | tr -d ' ')

if [ "$COUNT" -eq "1" ]; then
  echo "✓ Schema + data imported successfully into clean DB"
else
  echo "✗ Import into clean DB failed (expected 1 shop with id=1, got ${COUNT})"
  exit 1
fi
