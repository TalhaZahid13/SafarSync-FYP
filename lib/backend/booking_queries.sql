-- SafarSync Booking System Queries

-- ===== SINGLE BOOKING QUERIES =====

-- Create a single booking
INSERT INTO bookings (user_id, destination_id, booking_date, estimated_duration_days, notes, status)
VALUES (?, ?, ?, ?, ?, 'Planned');

-- Get user's bookings
SELECT b.*, d.name as destination_name, d.image_url, d.latitude, d.longitude
FROM bookings b
JOIN destinations d ON b.destination_id = d.destination_id
WHERE b.user_id = ?
ORDER BY b.created_at DESC;

-- Get booking details
SELECT b.*, d.name as destination_name, d.latitude, d.longitude,
       u.full_name, u.email
FROM bookings b
JOIN destinations d ON b.destination_id = d.destination_id
JOIN users u ON b.user_id = u.user_id
WHERE b.booking_id = ?;

-- Update booking status
UPDATE bookings SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE booking_id = ?;

-- Get all bookings count
SELECT COUNT(*) as total FROM bookings;

-- Get booking stats by status
SELECT
  COUNT(*) as total_bookings,
  SUM(CASE WHEN status = 'Planned' THEN 1 ELSE 0 END) as planned,
  SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) as active,
  SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) as completed
FROM bookings;

-- ===== GROUP BOOKING QUERIES =====

-- Create group booking
INSERT INTO group_bookings (trip_name, created_by, description, start_date, end_date, status)
VALUES (?, ?, ?, ?, ?, 'Planning');

-- Add creator as first member
INSERT INTO group_booking_members (group_booking_id, user_id)
VALUES (?, ?);

-- Get group booking details
SELECT gb.*, u.full_name as created_by_name, u.profile_picture_url as creator_profile
FROM group_bookings gb
JOIN users u ON gb.created_by = u.user_id
WHERE gb.group_booking_id = ?;

-- Get members of a group booking
SELECT u.user_id, u.full_name, u.email, u.profile_picture_url, gbm.joined_at
FROM group_booking_members gbm
JOIN users u ON gbm.user_id = u.user_id
WHERE gbm.group_booking_id = ?
ORDER BY gbm.joined_at;

-- Get member count for group
SELECT COUNT(*) as member_count FROM group_booking_members WHERE group_booking_id = ?;

-- Get user's group bookings
SELECT gb.*, u.full_name as created_by_name
FROM group_bookings gb
JOIN users u ON gb.created_by = u.user_id
WHERE gb.created_by = ? OR gb.group_booking_id IN (
  SELECT group_booking_id FROM group_booking_members WHERE user_id = ?
)
ORDER BY gb.created_at DESC;

-- Add member to group booking
INSERT INTO group_booking_members (group_booking_id, user_id)
VALUES (?, ?);

-- Update group booking status
UPDATE group_bookings SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE group_booking_id = ?;

-- Get member locations in group
SELECT u.user_id, u.full_name, u.profile_picture_url,
       ulu.latitude, ulu.longitude, ulu.city, ulu.country,
       ulu.captured_at, ulu.accuracy_meters
FROM group_booking_members gbm
JOIN users u ON gbm.user_id = u.user_id
LEFT JOIN user_location_updates ulu ON u.user_id = (
  SELECT user_id FROM user_location_updates
  WHERE user_identifier = CONCAT('user_', u.user_id)
  ORDER BY captured_at DESC LIMIT 1
) AND ulu.captured_at = (
  SELECT MAX(captured_at) FROM user_location_updates
  WHERE user_identifier = CONCAT('user_', u.user_id)
)
WHERE gbm.group_booking_id = ?
ORDER BY u.full_name;

-- ===== GROUP TRACKING QUERIES =====

-- Start tracking session
INSERT INTO group_tracking_sessions (group_booking_id, status)
VALUES (?, 'active');

-- Get active tracking sessions
SELECT * FROM group_tracking_sessions
WHERE status = 'active' AND group_booking_id = ?;

-- End tracking session
UPDATE group_tracking_sessions
SET status = 'ended', ended_at = CURRENT_TIMESTAMP
WHERE session_id = ?;

-- Get group booking stats
SELECT
  COUNT(DISTINCT gb.group_booking_id) as total_group_bookings,
  SUM(CASE WHEN gb.status = 'Planning' THEN 1 ELSE 0 END) as planning,
  SUM(CASE WHEN gb.status = 'Active' THEN 1 ELSE 0 END) as active,
  SUM(CASE WHEN gb.status = 'Completed' THEN 1 ELSE 0 END) as completed,
  COUNT(DISTINCT gbm.user_id) as total_members,
  COUNT(DISTINCT gts.session_id) as active_tracking_sessions
FROM group_bookings gb
LEFT JOIN group_booking_members gbm ON gb.group_booking_id = gbm.group_booking_id
LEFT JOIN group_tracking_sessions gts ON gb.group_booking_id = gts.group_booking_id
  AND gts.status = 'active';

-- ===== DASHBOARD STATS =====

-- Admin dashboard: Recent bookings
SELECT b.*, d.name as destination_name, u.full_name
FROM bookings b
JOIN destinations d ON b.destination_id = d.destination_id
JOIN users u ON b.user_id = u.user_id
ORDER BY b.created_at DESC LIMIT 10;

-- Admin dashboard: Recent group bookings
SELECT gb.*, u.full_name as created_by_name,
       (SELECT COUNT(*) FROM group_booking_members WHERE group_booking_id = gb.group_booking_id) as member_count
FROM group_bookings gb
JOIN users u ON gb.created_by = u.user_id
ORDER BY gb.created_at DESC LIMIT 10;

-- Aggregate stats
SELECT
  COUNT(*) as total_bookings,
  COUNT(DISTINCT user_id) as users_with_bookings,
  AVG(estimated_duration_days) as avg_duration
FROM bookings;
