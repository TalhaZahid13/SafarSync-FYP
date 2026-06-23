-- migration_v14: Fix booking FK constraint and sync destinations tables
-- Root cause: bookings.destination_id had FK -> destinations(destination_id)
-- but destinations was EMPTY while destination (singular) had 3 records.
-- This caused all booking creates to fail with ER_NO_REFERENCED_ROW_2.
-- Run after migration_v13.sql

USE safarsync;

-- 1. Drop the broken FK constraint
ALTER TABLE bookings DROP FOREIGN KEY IF EXISTS bookings_ibfk_2;

-- 2. Populate destinations table from destination (singular) data
INSERT IGNORE INTO destinations (destination_id, name, description, city, country, category, image_url, rating, review_count, average_cost)
SELECT
  d.destinationId,
  d.name,
  '',
  COALESCE(d.region, 'Pakistan'),
  'Pakistan',
  'Nature',
  COALESCE(d.image_url, d.image),
  COALESCE(d.rating, 0),
  COALESCE(d.review_count, 0),
  COALESCE(d.average_cost, 100)
FROM destination d;
