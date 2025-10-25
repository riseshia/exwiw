#!/bin/bash

set -e

export FROM_DATABASE_NAME="exwiw_scenario_prod_db"
export TO_DATABASE_NAME="exwiw_scenario_dev_db"

# Determine MySQL command based on environment
if [ -n "$CI" ]; then
  # CI environment: use mysql client directly
  MYSQL_CMD="mysql -h 127.0.0.1 -P 3306 -u root -prootpassword"
else
  # Local environment: use docker compose exec
  MYSQL_CMD="docker compose exec -T mysql mysql -u root"
fi

# Clean up
$MYSQL_CMD -e "DROP DATABASE IF EXISTS ${FROM_DATABASE_NAME}; CREATE DATABASE ${FROM_DATABASE_NAME};"
$MYSQL_CMD -e "DROP DATABASE IF EXISTS ${TO_DATABASE_NAME}; CREATE DATABASE ${TO_DATABASE_NAME};"

# Setup db
$MYSQL_CMD "${FROM_DATABASE_NAME}" < seed/mysql2-dump.sql
$MYSQL_CMD "${TO_DATABASE_NAME}" < seed/mysql2-dump.sql

# run exwiw
export DATABASE_PASSWORD="rootpassword"
bundle exec exe/exwiw \
  --adapter=mysql2 \
  --host=127.0.0.1 \
  --port=3306 \
  --user=root \
  --database="${FROM_DATABASE_NAME}" \
  --config-dir=scenario/mysql2-schema \
  --target-table=shops \
  --ids=1 \
  --output-dir=tmp/mysql2 \
  --log-level=debug

# import to db
for file in tmp/mysql2/delete-*.sql; do
  echo "Run ${file}"
  $MYSQL_CMD "${TO_DATABASE_NAME}" < "${file}"
done

for file in tmp/mysql2/insert-*.sql; do
  echo "Run ${file}"
  $MYSQL_CMD "${TO_DATABASE_NAME}" < "${file}"
done

# Verify insert works after import
echo "Testing insert after import..."
$MYSQL_CMD "${TO_DATABASE_NAME}" -e "INSERT INTO shops (id, name, updated_at, created_at) VALUES (999, 'Test Shop', '2025-01-01 00:00:00', '2025-01-01 00:00:00');"
COUNT=$($MYSQL_CMD "${TO_DATABASE_NAME}" -sN -e "SELECT COUNT(*) FROM shops WHERE id = 999;")

if [ "$COUNT" -eq "1" ]; then
  echo "✓ Insert after import works correctly"
else
  echo "✗ Insert after import failed"
  exit 1
fi
