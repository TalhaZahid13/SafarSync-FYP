-- migration_v13: Add missing auth columns to users table + fix route handler imports
-- Run after migration_v12.sql

USE safarsync;

-- Add auth_provider column if missing (required by firebase-exchange endpoint)
SET @col_auth = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'auth_provider'
);
SET @sql_auth = IF(@col_auth = 0,
  "ALTER TABLE users ADD COLUMN auth_provider ENUM('EMAIL','GOOGLE','APPLE','FACEBOOK') NOT NULL DEFAULT 'EMAIL' AFTER bio",
  'SELECT ''auth_provider already exists'''
);
PREPARE stmt FROM @sql_auth;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add role column if missing (required by JWT generation and user queries)
SET @col_role = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'role'
);
SET @sql_role = IF(@col_role = 0,
  "ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'user' AFTER auth_provider",
  'SELECT ''role already exists'''
);
PREPARE stmt FROM @sql_role;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
