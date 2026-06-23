-- Migration v10: Firebase ↔ MySQL Auth Synchronization
-- Run after migration_v9.sql

USE safarsync;

-- Add auth_provider column (EMAIL / GOOGLE / APPLE / FACEBOOK)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) NOT NULL DEFAULT 'EMAIL'
    COMMENT 'Firebase sign-in provider: EMAIL, GOOGLE, APPLE, FACEBOOK'
    AFTER firebase_uid;

-- Add role column for future RBAC (currently: user / admin)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'user'
    COMMENT 'Application role: user, admin'
    AFTER auth_provider;

-- Backfill: existing users without a firebase_uid are EMAIL users
UPDATE users SET auth_provider = 'EMAIL' WHERE auth_provider = 'EMAIL' OR auth_provider IS NULL;

-- Backfill: anyone with is_admin=1 gets role='admin'
UPDATE users SET role = 'admin' WHERE is_admin = 1 AND role = 'user';

-- Index for auth_provider filtering (admin dashboard)
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users (auth_provider);
CREATE INDEX IF NOT EXISTS idx_users_role          ON users (role);
