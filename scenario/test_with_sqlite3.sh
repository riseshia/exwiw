#!/bin/bash

set -e

TARGET_DB_PATH="tmp/scenario-target.sqlite3"
NEW_DB_PATH="tmp/scenario-target.sqlite3"

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
  --config-dir=scenario/schema \
  --target-table=shops \
  --ids=1 \
  --output-dir=tmp/sqlite3 \
  --log-level=debug

# import to db
bundle exec ruby scenario/import_with_sqlite3.rb $NEW_DB_PATH
