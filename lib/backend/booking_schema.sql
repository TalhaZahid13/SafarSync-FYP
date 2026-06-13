-- Bookings Schema (Feature 1 & 2)

-- Single Bookings Table
CREATE TABLE IF NOT EXISTS bookings (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  destination_id INT NOT NULL,
  booking_type ENUM('single') DEFAULT 'single',
  status ENUM('Planned', 'Active', 'Completed') DEFAULT 'Planned',
  booking_date DATE,
  estimated_duration_days INT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_destination_id (destination_id),
  INDEX idx_status (status),
  INDEX idx_booking_date (booking_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Group Bookings Table (Trip packages with multiple members)
CREATE TABLE group_bookings (
  group_booking_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_name VARCHAR(255) NOT NULL,
  created_by INT NOT NULL,
  status ENUM('Planning', 'Active', 'Completed') DEFAULT 'Planning',
  description TEXT,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_created_by (created_by),
  INDEX idx_status (status),
  INDEX idx_start_date (start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Group Booking Members
CREATE TABLE IF NOT EXISTS group_booking_members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_booking_id INT NOT NULL,
  user_id INT NOT NULL,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE KEY unique_booking_user (group_booking_id, user_id),
  INDEX idx_group_booking_id (group_booking_id),
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Group Booking Destinations
CREATE TABLE IF NOT EXISTS group_booking_destinations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_booking_id INT NOT NULL,
  destination_id INT NOT NULL,
  stop_order INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  INDEX idx_group_booking_id (group_booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Group Live Tracking Sessions
CREATE TABLE IF NOT EXISTS group_tracking_sessions (
  session_id INT AUTO_INCREMENT PRIMARY KEY,
  group_booking_id INT NOT NULL,
  status ENUM('active', 'paused', 'ended') DEFAULT 'active',
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP NULL,
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  INDEX idx_group_booking_id (group_booking_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Emergency Notification columns on users table
-- Run these once against your existing DB:
--   ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;
--   ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(500) NULL;

-- Emergency Alerts Table
CREATE TABLE IF NOT EXISTS emergency_alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  trip_id INT NULL,
  trip_type ENUM('single', 'group') NULL,
  latitude DECIMAL(10, 8) NOT NULL DEFAULT 0,
  longitude DECIMAL(11, 8) NOT NULL DEFAULT 0,
  message TEXT NULL,
  status ENUM('Active', 'Resolved', 'Cancelled') DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Emergency Contacts: add email column (run once against existing DB)
-- ALTER TABLE emergency_contacts ADD COLUMN IF NOT EXISTS contact_email VARCHAR(255) NULL AFTER contact_phone;

-- Group Invitations Table
CREATE TABLE IF NOT EXISTS group_invitations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_booking_id INT NOT NULL,
  sender_id INT NOT NULL,
  receiver_id INT NOT NULL,
  status ENUM('Pending', 'Accepted', 'Declined') DEFAULT 'Pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  UNIQUE KEY unique_invitation (group_booking_id, receiver_id),
  INDEX idx_receiver_id (receiver_id),
  INDEX idx_sender_id (sender_id),
  INDEX idx_group_booking_id (group_booking_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
