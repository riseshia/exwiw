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

# Verify insert works after import.
# A failed INSERT (e.g. PK collision) makes sqlite3 exit non-zero, so we
# evaluate it directly with `if` instead of doing a follow-up COUNT — `set -e`
# would otherwise kill the script before we could print a friendly diagnosis.
echo "Testing insert after import..."
if ! sqlite3 $NEW_DB_PATH "INSERT INTO shops (name, updated_at, created_at) VALUES ('Test Shop', '2025-01-01 00:00:00', '2025-01-01 00:00:00');"; then
  echo "✗ Insert after import failed"
  exit 1
fi
echo "✓ Insert after import works correctly (auto increment)"
