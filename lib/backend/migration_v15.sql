-- migration_v15: Add invite_code to group_bookings; wire groups flow to real tables
-- Run after migration_v14.sql
--
-- The app previously had a broken /api/groups route that referenced non-existent
-- `groups` and `group_members` tables. These routes now use the existing
-- `group_bookings` and `group_booking_members` tables instead. All that was
-- missing was an invite_code column on group_bookings.

USE safarsync;

-- 1. Add invite_code to group_bookings (unique, nullable)
ALTER TABLE group_bookings
  ADD COLUMN IF NOT EXISTS invite_code VARCHAR(20) UNIQUE;

-- 2. Back-fill invite codes for rows that have none
UPDATE group_bookings
SET    invite_code = CONCAT('GRP', LPAD(group_booking_id, 4, '0'))
WHERE  invite_code IS NULL OR invite_code = '';
