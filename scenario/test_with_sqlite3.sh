#!/bin/bash

TARGET_DB_PATH="tmp/scenario-target.sqlite3"

# Clean up
rm -rf tmp/sqlite3
mkdir -p tmp/sqlite3

# Setup db
cp scenario/initdb/init.sqlite3 $TARGET_DB_PATH

# run exwiw
bundle exec exe/exwiw \
  --adapter=sqlite3 \
  --database="${TARGET_DB_PATH}" \
  --config=scenario/schema.json \
  --target-table=shops \
  --ids=1 \
  --output-dir=tmp/sqlite3

# import to db
