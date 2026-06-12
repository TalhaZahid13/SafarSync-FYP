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
CREATE TABLE IF NOT EXISTS group_bookings (
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
