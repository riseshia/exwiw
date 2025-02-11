#!/bin/bash

set -e

export FROM_DATABASE_NAME="exwiw_scenario_prod_db"
export TO_DATABASE_NAME="exwiw_scenario_dev_db"

# Clean up
docker compose exec -T mysql mysql -u root -e "DROP DATABASE IF EXISTS ${FROM_DATABASE_NAME}; CREATE DATABASE ${FROM_DATABASE_NAME};"
docker compose exec -T mysql mysql -u root -e "DROP DATABASE IF EXISTS ${TO_DATABASE_NAME}; CREATE DATABASE ${TO_DATABASE_NAME};"

# Setup db
docker compose exec -T mysql mysql -u root "${FROM_DATABASE_NAME}" < seed/mysql2-dump.sql
docker compose exec -T mysql mysql -u root "${TO_DATABASE_NAME}" < seed/mysql2-dump.sql

# run exwiw
export DATABASE_PASSWORD="rootpassword"
bundle exec exe/exwiw \
  --adapter=mysql2 \
  --host=127.0.0.1 \
  --port=3306 \
  --user=root \
  --database="${FROM_DATABASE_NAME}" \
  --config=scenario/schema.json \
  --target-table=shops \
  --ids=1 \
  --output-dir=tmp/mysql2

# import to db
for file in tmp/mysql2/delete-*.sql; do
  echo "Run ${file}"
  docker compose exec -T mysql mysql -u root "${TO_DATABASE_NAME}" < "${file}"
done

for file in tmp/mysql2/insert-*.sql; do
  echo "Run ${file}"
  docker compose exec -T mysql mysql -u root "${TO_DATABASE_NAME}" < "${file}"
done
