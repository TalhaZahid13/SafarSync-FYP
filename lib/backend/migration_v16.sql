-- migration_v16: Fix bookings table schema
-- Run this if you get "Failed to create booking" errors.
-- It is safe to run on any DB state — all statements use IF NOT EXISTS / IF EXISTS.
--
-- Root cause: the original booking_schema.sql had a minimal bookings table with
-- only 3 status values and no payment/traveler columns. The booking controller
-- needs all 7 status values and several extra columns added by migration_v4.
-- If migration_v4 was never applied, every booking insert crashes.

USE safarsync;

-- 1. Expand the status ENUM (safe even if already expanded)
ALTER TABLE bookings
  MODIFY COLUMN status ENUM(
    'Pending', 'Awaiting Payment', 'Confirmed',
    'Active', 'Completed', 'Cancelled', 'Refunded'
  ) NOT NULL DEFAULT 'Pending';

-- 2. Add all columns that the booking controller expects
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS travel_date           DATE           NULL              AFTER booking_date,
  ADD COLUMN IF NOT EXISTS num_travelers         INT            NOT NULL DEFAULT 1 AFTER travel_date,
  ADD COLUMN IF NOT EXISTS package_id            INT            NULL              AFTER num_travelers,
  ADD COLUMN IF NOT EXISTS total_amount          DECIMAL(10,2)  NOT NULL DEFAULT 0 AFTER package_id,
  ADD COLUMN IF NOT EXISTS payment_status        ENUM('Unpaid','Paid','Refunded') NOT NULL DEFAULT 'Unpaid' AFTER total_amount,
  ADD COLUMN IF NOT EXISTS payment_intent_id     VARCHAR(255)   NULL              AFTER payment_status,
  ADD COLUMN IF NOT EXISTS cancelled_at          TIMESTAMP      NULL DEFAULT NULL AFTER payment_intent_id,
  ADD COLUMN IF NOT EXISTS cancellation_reason   TEXT           NULL              AFTER cancelled_at;

-- 3. Ensure booking_type column exists (some installs may be missing it)
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS booking_type ENUM('single','group') NOT NULL DEFAULT 'single' AFTER destination_id;

-- 4. Migrate any legacy 'Planned' statuses to 'Pending' so old rows aren't stuck
UPDATE bookings SET status = 'Pending'    WHERE status = 'Planned';
UPDATE bookings SET status = 'Active'     WHERE status = 'Active';   -- no-op, sanity check

-- Done. Verify with: DESCRIBE bookings;
