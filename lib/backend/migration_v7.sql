-- migration_v7: Destination-based theme preference
-- Run once in MySQL after migration_v6.sql

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS theme_preference VARCHAR(20) NOT NULL DEFAULT 'default';

-- Constrain to valid values at DB level
ALTER TABLE users
  ADD CONSTRAINT chk_theme_preference
  CHECK (theme_preference IN ('default','snow','desert','beach','mountain','forest','urban'));
