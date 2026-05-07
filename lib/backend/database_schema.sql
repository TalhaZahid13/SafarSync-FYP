-- SafarSync Database Schema
-- Run this file to create all necessary tables

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20),
  profile_picture_url VARCHAR(500),
  blood_group VARCHAR(10),
  bio TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  INDEX idx_email (email)
);

-- Destinations Table
CREATE TABLE IF NOT EXISTS destinations (
  destination_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  city VARCHAR(100),
  country VARCHAR(100),
  category VARCHAR(100),
  image_url VARCHAR(500),
  rating DECIMAL(3, 2),
  review_count INT DEFAULT 0,
  popularity_score INT DEFAULT 0,
  weather_data JSON,
  best_time_to_visit VARCHAR(100),
  average_cost DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_city_country (city, country),
  INDEX idx_category (category),
  FULLTEXT INDEX ft_name_description (name, description)
);

-- Routes Table
CREATE TABLE IF NOT EXISTS routes (
  route_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  route_name VARCHAR(255) NOT NULL,
  description TEXT,
  start_location VARCHAR(255),
  end_location VARCHAR(255),
  start_lat DECIMAL(10, 8),
  start_lng DECIMAL(11, 8),
  end_lat DECIMAL(10, 8),
  end_lng DECIMAL(11, 8),
  total_distance DECIMAL(10, 2),
  estimated_duration INT,
  route_data JSON,
  difficulty_level VARCHAR(50),
  weather_optimized BOOLEAN,
  traffic_considered BOOLEAN,
  is_public BOOLEAN DEFAULT FALSE,
  views_count INT DEFAULT 0,
  rating DECIMAL(3, 2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
);

-- Route Stops/Waypoints Table
CREATE TABLE IF NOT EXISTS route_stops (
  stop_id INT AUTO_INCREMENT PRIMARY KEY,
  route_id INT NOT NULL,
  destination_id INT,
  stop_order INT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  stop_name VARCHAR(255),
  duration_at_stop INT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id) REFERENCES routes(route_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_route_id (route_id)
);

-- Wishlists Table
CREATE TABLE IF NOT EXISTS wishlists (
  wishlist_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  destination_id INT NOT NULL,
  notes TEXT,
  priority VARCHAR(50),
  planned_visit_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user_destination (user_id, destination_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);

-- Reviews/Ratings Table
CREATE TABLE IF NOT EXISTS reviews (
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  destination_id INT,
  route_id INT,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(255),
  review_text TEXT,
  images JSON,
  helpful_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  FOREIGN KEY (route_id) REFERENCES routes(route_id) ON DELETE CASCADE,
  INDEX idx_destination_id (destination_id),
  INDEX idx_user_id (user_id)
);

-- Emergency Contacts Table (ICE - In Case of Emergency)
CREATE TABLE IF NOT EXISTS emergency_contacts (
  contact_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  contact_name VARCHAR(255) NOT NULL,
  contact_phone VARCHAR(20) NOT NULL,
  relationship VARCHAR(100),
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);

-- Emergency SOS Events Table
CREATE TABLE IF NOT EXISTS emergency_events (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  location_description VARCHAR(500),
  severity VARCHAR(50),
  status VARCHAR(50),
  shared_with_contacts BOOLEAN DEFAULT TRUE,
  shared_with_authorities BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
);

-- AI Chat History Table
CREATE TABLE IF NOT EXISTS ai_chat_history (
  chat_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  user_message TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  context_data JSON,
  helpful_rating INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  notification_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(100),
  related_route_id INT,
  related_destination_id INT,
  is_read BOOLEAN DEFAULT FALSE,
  action_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (related_route_id) REFERENCES routes(route_id) ON DELETE SET NULL,
  FOREIGN KEY (related_destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_is_read (is_read),
  INDEX idx_created_at (created_at)
);

-- Weather Cache Table
CREATE TABLE IF NOT EXISTS weather_cache (
  cache_id INT AUTO_INCREMENT PRIMARY KEY,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  weather_data JSON,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_location (latitude, longitude),
  INDEX idx_expires_at (expires_at)
);

-- User Location Updates Table
CREATE TABLE IF NOT EXISTS user_location_updates (
  location_update_id INT AUTO_INCREMENT PRIMARY KEY,
  user_identifier VARCHAR(128),
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  city VARCHAR(100),
  country VARCHAR(100),
  accuracy_meters DECIMAL(10, 2),
  captured_at DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_identifier (user_identifier),
  INDEX idx_captured_at (captured_at)
);

-- User Preferences Table
CREATE TABLE IF NOT EXISTS user_preferences (
  preference_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNIQUE NOT NULL,
  language VARCHAR(10),
  theme VARCHAR(50),
  notifications_enabled BOOLEAN DEFAULT TRUE,
  weather_alerts BOOLEAN DEFAULT TRUE,
  traffic_alerts BOOLEAN DEFAULT TRUE,
  emergency_sharing_enabled BOOLEAN DEFAULT TRUE,
  preferred_categories JSON,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- AI Recommendations Table
CREATE TABLE IF NOT EXISTS ai_recommendations (
  recommendation_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  destination_id INT,
  reason TEXT,
  confidence_score DECIMAL(3, 2),
  recommended_visit_date DATE,
  viewed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);

-- Traveler table (for backward compatibility)
CREATE TABLE IF NOT EXISTS Traveler (
  userId INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  passwordHash VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  phoneNumber VARCHAR(20),
  bloodGroup VARCHAR(10),
  lastLocation VARCHAR(255),
  last_location VARCHAR(255),
  last_latitude DECIMAL(10, 8),
  last_longitude DECIMAL(11, 8),
  lastLocationUpdatedAt DATETIME,
  last_location_updated_at DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
);

-- Tour Packages table
CREATE TABLE IF NOT EXISTS tour_packages (
  package_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  destination_id INT,
  price DECIMAL(10, 2),
  duration_days INT,
  max_travelers INT,
  start_date DATE,
  end_date DATE,
  itinerary JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL
);
