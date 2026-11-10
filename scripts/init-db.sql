-- Database initialization script for development
-- This script sets up the database for local development

-- Create any additional extensions if needed
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- The main database 'neondb' is automatically created by the POSTGRES_DB environment variable
-- Additional setup can be done here if needed

-- Create a simple health check table for monitoring
CREATE TABLE IF NOT EXISTS _health_check (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'ok'
);

-- Insert a test record
INSERT INTO _health_check (status) VALUES ('initialized') ON CONFLICT DO NOTHING;