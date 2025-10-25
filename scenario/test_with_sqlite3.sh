#!/bin/bash

set -e

TARGET_DB_PATH="tmp/scenario-target.sqlite3"
NEW_DB_PATH="tmp/scenario-new.sqlite3"

# Clean up
rm -rf tmp/sqlite3
mkdir -p tmp/sqlite3

# Setup db
cp scenario/initdb/init.sqlite3 $TARGET_DB_PATH
cp scenario/initdb/init.sqlite3 $NEW_DB_PATH

# run exwiw
bundle exec exe/exwiw \
  --adapter=sqlite3 \
  --database="${TARGET_DB_PATH}" \
  --config-dir=scenario/sqlite3-schema \
  --target-table=shops \
  --ids=1 \
  --output-dir=tmp/sqlite3 \
  --log-level=debug

# import to db
bundle exec ruby scenario/import_with_sqlite3.rb $NEW_DB_PATH

# Verify insert works after import
echo "Testing insert after import..."
sqlite3 $NEW_DB_PATH "INSERT INTO shops (id, name, updated_at, created_at) VALUES (999, 'Test Shop', '2025-01-01 00:00:00', '2025-01-01 00:00:00');"
COUNT=$(sqlite3 $NEW_DB_PATH "SELECT COUNT(*) FROM shops WHERE id = 999;")

if [ "$COUNT" -eq "1" ]; then
  echo "✓ Insert after import works correctly"
else
  echo "✗ Insert after import failed"
  exit 1
fi
