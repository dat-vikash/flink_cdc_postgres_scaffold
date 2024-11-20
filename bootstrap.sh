#!/bin/bash

set -e

# Ensure the Docker containers are running
echo "Starting Docker containers..."
docker-compose up -d

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL containers to be ready..."
until docker exec postgres-primary pg_isready -U postgres &> /dev/null; do
  sleep 2
done

# Setup primary database
echo "Setting up the primary database..."
docker exec -i postgres-primary psql -U postgres -d primary_db < sql/primary_db_setup.sql

# Configure replication
echo "Configuring replication settings..."
docker exec postgres-primary psql -U postgres -d primary_db -c "
  CREATE PUBLICATION flink_cdc;
"
docker exec postgres-primary psql -U postgres -d primary_db -c "
  SELECT pg_create_logical_replication_slot('flink_cdc_slot', 'pgoutput');
  ALTER PUBLICATION flink_cdc ADD TABLE users;
  select * from pg_catalog.pg_publication_tables
where pubname = 'flink_cdc';
"

# Configure replica database
echo "Setting up the replica database..."
docker exec postgres-replica psql -U postgres -d replica_db < sql/replica_db_setup.sql

docker exec postgres-replica psql -U postgres -d replica_db -c "
create subscription test_subscription CONNECTION 'dbname=primary_db host=postgres-primary user=postgres password=postgres' PUBLICATION flink_cdc;  
"
echo "Replication setup is complete. Configure the replica to start syncing."

