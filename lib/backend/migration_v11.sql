-- Migration v11: Add city field to users table
-- Run after migration_v10.sql

USE safarsync;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS city VARCHAR(100) DEFAULT NULL
    COMMENT 'User home city for personalization'
    AFTER phone_number;

CREATE INDEX IF NOT EXISTS idx_users_city ON users (city);
