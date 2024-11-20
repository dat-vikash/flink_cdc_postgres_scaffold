-- Create schema and configure table for replication
DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    test text,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable REPLICA IDENTITY FULL for CDC compatibility
ALTER TABLE users REPLICA IDENTITY FULL;

-- Grant replication role
CREATE ROLE replica WITH REPLICATION PASSWORD 'replica' LOGIN;
