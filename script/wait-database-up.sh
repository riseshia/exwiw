#!/bin/bash

# wait for database to be ready
while ! docker compose exec postgres psql -U postgres -c "SELECT 1" > /dev/null 2>&1; do
  echo "Waiting for postgres to be ready..."
  sleep 1
done

# XXX: Disable temparary. mysql in compose fail to launch, we can't test it.
# while ! docker compose exec mysql mysql -u root -e "SELECT 1" > /dev/null 2>&1; do
#   echo "Waiting for mysql to be ready..."
#   sleep 1
# done
