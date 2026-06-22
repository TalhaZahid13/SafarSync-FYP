-- SafarSync Migration V4: Full Booking + Payment System
-- Run this against your MySQL database after migration_v3.sql

-- ─── 1. bookings: expand status lifecycle, add missing columns ────────────────
ALTER TABLE bookings
  MODIFY COLUMN status ENUM(
    'Pending', 'Awaiting Payment', 'Confirmed',
    'Active', 'Completed', 'Cancelled', 'Refunded'
  ) DEFAULT 'Pending';

ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS travel_date DATE NULL AFTER booking_date,
  ADD COLUMN IF NOT EXISTS num_travelers INT NOT NULL DEFAULT 1 AFTER travel_date,
  ADD COLUMN IF NOT EXISTS package_id INT NULL AFTER num_travelers,
  ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2) DEFAULT 0 AFTER package_id,
  ADD COLUMN IF NOT EXISTS payment_status ENUM('Unpaid','Paid','Refunded') DEFAULT 'Unpaid' AFTER total_amount,
  ADD COLUMN IF NOT EXISTS payment_intent_id VARCHAR(255) NULL AFTER payment_status,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP NULL AFTER payment_intent_id,
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT NULL AFTER cancelled_at;

-- ─── 2. group_bookings: expand status, add columns ───────────────────────────
ALTER TABLE group_bookings
  MODIFY COLUMN status ENUM(
    'Planning', 'Open', 'Full', 'Active', 'Completed', 'Cancelled'
  ) DEFAULT 'Planning';

ALTER TABLE group_bookings
  ADD COLUMN IF NOT EXISTS max_members INT DEFAULT 20 AFTER description,
  ADD COLUMN IF NOT EXISTS destination_id INT NULL AFTER max_members,
  ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2) DEFAULT 0 AFTER destination_id,
  ADD COLUMN IF NOT EXISTS payment_type ENUM('individual','full') DEFAULT 'individual' AFTER total_amount;

-- ─── 3. group_booking_members: add role ──────────────────────────────────────
ALTER TABLE group_booking_members
  ADD COLUMN IF NOT EXISTS role ENUM('organizer','member') DEFAULT 'member' AFTER user_id;

-- ─── 4. payments table ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  booking_id INT NULL,
  group_booking_id INT NULL,
  stripe_payment_intent_id VARCHAR(255) UNIQUE,
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(10) DEFAULT 'usd',
  status ENUM('pending','succeeded','failed','refunded') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_booking_id (booking_id),
  INDEX idx_stripe_intent (stripe_payment_intent_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 5. transactions table ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  payment_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status ENUM('pending','completed','failed','refunded') DEFAULT 'pending',
  transaction_reference VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
  INDEX idx_payment_id (payment_id),
  INDEX idx_transaction_reference (transaction_reference)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 6. tour_packages: ensure price column exists ────────────────────────────
ALTER TABLE tour_packages
  ADD COLUMN IF NOT EXISTS price_per_day DECIMAL(10,2) DEFAULT 50.00 AFTER price;
