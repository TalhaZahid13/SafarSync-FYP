-- ============================================================================
-- SafarSync — Complete Master Migration Script
-- Version: 10.0 (consolidated)
-- Generated: 2026-06-23
--
-- PURPOSE: Single executable script that brings ANY SafarSync MySQL database
-- (empty or partial) to the full production schema required by the current
-- Flutter + Node.js codebase.
--
-- SAFE TO RUN:
--   • Uses CREATE TABLE IF NOT EXISTS everywhere — no data loss on re-run.
--   • Uses ALTER TABLE ... ADD COLUMN IF NOT EXISTS — harmless on existing cols.
--   • Never drops production tables.
--   • Old legacy tables (admin, traveler, emergencycontact, etc.) are left
--     intact and new parallel tables are created alongside them.
--
-- EXECUTION ORDER: Run top-to-bottom in a single session.
--   SQLyog      → File → Execute SQL Script
--   MySQL WB    → File → Run SQL Script
--   phpMyAdmin  → Import tab, select this file
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATABASE
-- ============================================================================

CREATE DATABASE IF NOT EXISTS safarsync
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE safarsync;

-- ============================================================================
-- SECTION 2: BASE TABLES
-- (Core entities — no dependencies on other new tables)
-- ============================================================================

-- --------------------------------------------------------------------------
-- 2.1  users
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  user_id                INT            NOT NULL AUTO_INCREMENT,
  firebase_uid           VARCHAR(128)   NULL UNIQUE COMMENT 'Firebase Auth UID',
  email                  VARCHAR(255)   NOT NULL UNIQUE,
  password_hash          VARCHAR(255)   NOT NULL,
  full_name              VARCHAR(255)   NOT NULL,
  phone_number           VARCHAR(20)    NULL,
  profile_picture_url    VARCHAR(500)   NULL,
  blood_group            VARCHAR(10)    NULL,
  bio                    TEXT           NULL,
  is_active              TINYINT(1)     NOT NULL DEFAULT 1,
  is_admin               TINYINT(1)     NOT NULL DEFAULT 0,
  is_blocked             TINYINT(1)     NOT NULL DEFAULT 0,
  suspended_at           TIMESTAMP      NULL DEFAULT NULL,
  suspended_reason       VARCHAR(500)   NULL DEFAULT NULL,
  last_login_at          TIMESTAMP      NULL DEFAULT NULL,
  theme_preference       VARCHAR(20)    NOT NULL DEFAULT 'default'
                         COMMENT 'auto-set from booking destination',
  created_at             TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  INDEX idx_users_email        (email),
  INDEX idx_users_firebase_uid (firebase_uid),
  INDEX idx_users_is_admin     (is_admin),
  CONSTRAINT chk_theme_preference CHECK (
    theme_preference IN ('default','snow','desert','beach','mountain','forest','urban')
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 2.2  admins  (completely separate admin authentication — NOT users)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admins (
  admin_id          INT           NOT NULL AUTO_INCREMENT,
  email             VARCHAR(255)  NOT NULL UNIQUE,
  password_hash     VARCHAR(255)  NOT NULL,
  full_name         VARCHAR(255)  NOT NULL,
  role              ENUM('super_admin','moderator') NOT NULL DEFAULT 'moderator',
  is_active         TINYINT(1)    NOT NULL DEFAULT 1,
  last_login        DATETIME      NULL,
  reset_otp         VARCHAR(255)  NULL,
  reset_otp_expires DATETIME      NULL,
  created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (admin_id),
  INDEX idx_admins_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 2.3  destinations
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS destinations (
  destination_id      INT            NOT NULL AUTO_INCREMENT,
  name                VARCHAR(255)   NOT NULL,
  description         TEXT           NULL,
  latitude            DECIMAL(10,8)  NOT NULL,
  longitude           DECIMAL(11,8)  NOT NULL,
  city                VARCHAR(100)   NULL,
  country             VARCHAR(100)   NULL,
  category            VARCHAR(100)   NULL,
  image_url           VARCHAR(500)   NULL,
  rating              DECIMAL(3,2)   NULL,
  review_count        INT            NOT NULL DEFAULT 0,
  popularity_score    INT            NOT NULL DEFAULT 0,
  weather_data        JSON           NULL,
  best_time_to_visit  VARCHAR(100)   NULL,
  average_cost        DECIMAL(10,2)  NULL DEFAULT NULL,
  created_at          TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (destination_id),
  INDEX idx_dest_city_country (city, country),
  INDEX idx_dest_category     (category),
  FULLTEXT INDEX ft_dest_name_desc (name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 2.4  user_preferences
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_preferences (
  preference_id              INT          NOT NULL AUTO_INCREMENT,
  user_id                    INT          NOT NULL UNIQUE,
  language                   VARCHAR(10)  NULL DEFAULT 'en',
  theme                      VARCHAR(50)  NULL DEFAULT 'light',
  notifications_enabled      TINYINT(1)   NOT NULL DEFAULT 1,
  weather_alerts             TINYINT(1)   NOT NULL DEFAULT 1,
  traffic_alerts             TINYINT(1)   NOT NULL DEFAULT 1,
  emergency_sharing_enabled  TINYINT(1)   NOT NULL DEFAULT 1,
  preferred_categories       JSON         NULL,
  updated_at                 TIMESTAMP    NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (preference_id),
  CONSTRAINT fk_upref_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 2.5  weather_cache
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS weather_cache (
  cache_id     INT            NOT NULL AUTO_INCREMENT,
  latitude     DECIMAL(10,8)  NOT NULL,
  longitude    DECIMAL(11,8)  NOT NULL,
  weather_data JSON           NOT NULL,
  expires_at   TIMESTAMP      NOT NULL,
  created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (cache_id),
  UNIQUE KEY uq_weather_location (latitude, longitude),
  INDEX idx_weather_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 3: BOOKING SYSTEM
-- ============================================================================

-- --------------------------------------------------------------------------
-- 3.1  bookings  (single / individual bookings)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bookings (
  booking_id              INT            NOT NULL AUTO_INCREMENT,
  user_id                 INT            NOT NULL,
  destination_id          INT            NOT NULL,
  booking_date            DATE           NULL,
  travel_date             DATE           NULL,
  num_travelers           INT            NOT NULL DEFAULT 1,
  package_id              INT            NULL,
  estimated_duration_days INT            NOT NULL DEFAULT 1,
  total_amount            DECIMAL(10,2)  NOT NULL DEFAULT 0,
  notes                   TEXT           NULL,
  status                  ENUM(
    'Pending','Awaiting Payment','Confirmed',
    'Active','Completed','Cancelled','Refunded'
  )                                      NOT NULL DEFAULT 'Pending',
  payment_status          ENUM('Unpaid','Paid','Refunded') NOT NULL DEFAULT 'Unpaid',
  payment_intent_id       VARCHAR(255)   NULL,
  cancelled_at            TIMESTAMP      NULL DEFAULT NULL,
  cancellation_reason     TEXT           NULL,
  created_at              TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at              TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (booking_id),
  CONSTRAINT fk_booking_user        FOREIGN KEY (user_id)        REFERENCES users(user_id)        ON DELETE CASCADE,
  CONSTRAINT fk_booking_destination FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE RESTRICT,
  INDEX idx_booking_user_id       (user_id),
  INDEX idx_booking_destination   (destination_id),
  INDEX idx_booking_status        (status),
  INDEX idx_booking_payment_status(payment_status),
  INDEX idx_booking_travel_date   (travel_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 3.2  group_bookings
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS group_bookings (
  group_booking_id  INT            NOT NULL AUTO_INCREMENT,
  trip_name         VARCHAR(255)   NOT NULL,
  created_by        INT            NOT NULL,
  description       TEXT           NULL,
  max_members       INT            NOT NULL DEFAULT 20,
  destination_id    INT            NULL,
  total_amount      DECIMAL(10,2)  NOT NULL DEFAULT 0,
  payment_type      ENUM('individual','full') NOT NULL DEFAULT 'individual',
  start_date        DATE           NULL,
  end_date          DATE           NULL,
  status            ENUM('Planning','Open','Full','Active','Completed','Cancelled')
                                   NOT NULL DEFAULT 'Planning',
  created_at        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (group_booking_id),
  CONSTRAINT fk_gb_creator     FOREIGN KEY (created_by)     REFERENCES users(user_id)        ON DELETE CASCADE,
  CONSTRAINT fk_gb_destination FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_gb_created_by (created_by),
  INDEX idx_gb_status     (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 3.3  group_booking_members
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS group_booking_members (
  id               INT       NOT NULL AUTO_INCREMENT,
  group_booking_id INT       NOT NULL,
  user_id          INT       NOT NULL,
  role             ENUM('organizer','member') NOT NULL DEFAULT 'member',
  joined_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_gbm_member (group_booking_id, user_id),
  CONSTRAINT fk_gbm_group FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  CONSTRAINT fk_gbm_user  FOREIGN KEY (user_id)          REFERENCES users(user_id)                   ON DELETE CASCADE,
  INDEX idx_gbm_group (group_booking_id),
  INDEX idx_gbm_user  (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 3.4  group_invitations
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS group_invitations (
  id               INT       NOT NULL AUTO_INCREMENT,
  group_booking_id INT       NOT NULL,
  sender_id        INT       NOT NULL,
  receiver_id      INT       NOT NULL,
  status           ENUM('Pending','Accepted','Declined') NOT NULL DEFAULT 'Pending',
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_ginv_group    FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  CONSTRAINT fk_ginv_sender   FOREIGN KEY (sender_id)        REFERENCES users(user_id)                   ON DELETE CASCADE,
  CONSTRAINT fk_ginv_receiver FOREIGN KEY (receiver_id)      REFERENCES users(user_id)                   ON DELETE CASCADE,
  INDEX idx_ginv_receiver (receiver_id),
  INDEX idx_ginv_group    (group_booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 3.5  group_chat_messages
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS group_chat_messages (
  message_id       INT       NOT NULL AUTO_INCREMENT,
  group_booking_id INT       NOT NULL,
  user_id          INT       NOT NULL,
  message          TEXT      NOT NULL,
  message_type     ENUM('text','image','location','system') NOT NULL DEFAULT 'text',
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (message_id),
  CONSTRAINT fk_gcm_group FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  CONSTRAINT fk_gcm_user  FOREIGN KEY (user_id)          REFERENCES users(user_id)                   ON DELETE CASCADE,
  INDEX idx_gcm_group_time (group_booking_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 3.6  group_tracking_sessions  (live GPS sharing during group trips)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS group_tracking_sessions (
  id               INT       NOT NULL AUTO_INCREMENT,
  group_booking_id INT       NOT NULL,
  status           ENUM('active','ended') NOT NULL DEFAULT 'active',
  started_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ended_at         TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_gts_group FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  INDEX idx_gts_group  (group_booking_id),
  INDEX idx_gts_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 4: PAYMENTS & TRANSACTIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- 4.1  payments
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
  id                        INT            NOT NULL AUTO_INCREMENT,
  user_id                   INT            NOT NULL,
  booking_id                INT            NULL,
  group_booking_id          INT            NULL,
  stripe_payment_intent_id  VARCHAR(255)   NULL UNIQUE,
  amount                    DECIMAL(10,2)  NOT NULL,
  currency                  VARCHAR(10)    NOT NULL DEFAULT 'usd',
  status                    ENUM('pending','succeeded','failed','refunded')
                                           NOT NULL DEFAULT 'pending',
  refund_requested_at       TIMESTAMP      NULL DEFAULT NULL,
  refund_approved_at        TIMESTAMP      NULL DEFAULT NULL,
  refund_rejected_at        TIMESTAMP      NULL DEFAULT NULL,
  refund_admin_notes        VARCHAR(500)   NULL DEFAULT NULL,
  created_at                TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_pay_user  FOREIGN KEY (user_id)         REFERENCES users(user_id)         ON DELETE CASCADE,
  CONSTRAINT fk_pay_book  FOREIGN KEY (booking_id)      REFERENCES bookings(booking_id)   ON DELETE SET NULL,
  CONSTRAINT fk_pay_group FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE SET NULL,
  INDEX idx_pay_user          (user_id),
  INDEX idx_pay_booking       (booking_id),
  INDEX idx_pay_group_booking (group_booking_id),
  INDEX idx_pay_status        (status),
  INDEX idx_pay_stripe        (stripe_payment_intent_id),
  INDEX idx_pay_refund_req    (refund_requested_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 4.2  transactions  (individual debit/credit ledger entries)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS transactions (
  id                     INT            NOT NULL AUTO_INCREMENT,
  payment_id             INT            NOT NULL,
  amount                 DECIMAL(10,2)  NOT NULL,
  status                 ENUM('pending','completed','failed','refunded')
                                        NOT NULL DEFAULT 'pending',
  transaction_reference  VARCHAR(255)   NULL COMMENT 'Stripe charge / refund ID',
  created_at             TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_txn_payment FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
  INDEX idx_txn_payment   (payment_id),
  INDEX idx_txn_reference (transaction_reference),
  INDEX idx_txn_status    (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 5: ROUTES & WISHLIST
-- ============================================================================

-- --------------------------------------------------------------------------
-- 5.1  routes
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS routes (
  route_id            INT            NOT NULL AUTO_INCREMENT,
  user_id             INT            NOT NULL,
  route_name          VARCHAR(255)   NOT NULL,
  description         TEXT           NULL,
  start_location      VARCHAR(255)   NULL,
  end_location        VARCHAR(255)   NULL,
  start_lat           DECIMAL(10,8)  NULL,
  start_lng           DECIMAL(11,8)  NULL,
  end_lat             DECIMAL(10,8)  NULL,
  end_lng             DECIMAL(11,8)  NULL,
  total_distance      DECIMAL(10,2)  NULL,
  estimated_duration  INT            NULL COMMENT 'minutes',
  route_data          JSON           NULL,
  difficulty_level    VARCHAR(50)    NULL,
  weather_optimized   TINYINT(1)     NULL DEFAULT 0,
  traffic_considered  TINYINT(1)     NULL DEFAULT 0,
  is_public           TINYINT(1)     NOT NULL DEFAULT 0,
  views_count         INT            NOT NULL DEFAULT 0,
  rating              DECIMAL(3,2)   NULL,
  created_at          TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (route_id),
  CONSTRAINT fk_route_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_route_user_id   (user_id),
  INDEX idx_route_created   (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 5.2  route_stops
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS route_stops (
  stop_id          INT            NOT NULL AUTO_INCREMENT,
  route_id         INT            NOT NULL,
  destination_id   INT            NULL,
  stop_order       INT            NOT NULL DEFAULT 0,
  latitude         DECIMAL(10,8)  NULL,
  longitude        DECIMAL(11,8)  NULL,
  stop_name        VARCHAR(255)   NULL,
  duration_at_stop INT            NULL COMMENT 'minutes',
  notes            TEXT           NULL,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (stop_id),
  CONSTRAINT fk_rstop_route FOREIGN KEY (route_id)       REFERENCES routes(route_id)           ON DELETE CASCADE,
  CONSTRAINT fk_rstop_dest  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_rstop_route (route_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 5.3  wishlists
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wishlists (
  wishlist_id          INT          NOT NULL AUTO_INCREMENT,
  user_id              INT          NOT NULL,
  destination_id       INT          NOT NULL,
  notes                TEXT         NULL,
  priority             VARCHAR(50)  NULL,
  planned_visit_date   DATE         NULL,
  created_at           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (wishlist_id),
  UNIQUE KEY uq_wishlist_user_dest (user_id, destination_id),
  CONSTRAINT fk_wl_user FOREIGN KEY (user_id)       REFERENCES users(user_id)             ON DELETE CASCADE,
  CONSTRAINT fk_wl_dest FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  INDEX idx_wl_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 5.4  reviews
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
  review_id     INT          NOT NULL AUTO_INCREMENT,
  user_id       INT          NOT NULL,
  destination_id INT         NULL,
  route_id      INT          NULL,
  rating        INT          NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title         VARCHAR(255) NULL,
  review_text   TEXT         NULL,
  images        JSON         NULL,
  helpful_count INT          NOT NULL DEFAULT 0,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (review_id),
  CONSTRAINT fk_rev_user FOREIGN KEY (user_id)        REFERENCES users(user_id)             ON DELETE CASCADE,
  CONSTRAINT fk_rev_dest FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  CONSTRAINT fk_rev_route FOREIGN KEY (route_id)      REFERENCES routes(route_id)            ON DELETE CASCADE,
  INDEX idx_rev_dest    (destination_id),
  INDEX idx_rev_user    (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 6: TOUR PACKAGES & BUDGET PLANNER
-- ============================================================================

-- --------------------------------------------------------------------------
-- 6.1  tour_packages  (Sasta Tour / Admin-managed packages)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tour_packages (
  package_id       INT            NOT NULL AUTO_INCREMENT,
  title            VARCHAR(255)   NOT NULL,
  description      TEXT           NULL,
  duration_days    INT            NOT NULL DEFAULT 3,
  total_price      DECIMAL(12,2)  NOT NULL DEFAULT 0,
  price_per_day    DECIMAL(10,2)  NOT NULL DEFAULT 50.00,
  category         VARCHAR(100)   NOT NULL DEFAULT 'General',
  destinations     JSON           NULL,
  itinerary        JSON           NULL,
  max_travelers    INT            NOT NULL DEFAULT 10,
  includes         JSON           NULL COMMENT 'Array of included items',
  image_url        VARCHAR(500)   NULL,
  is_active        TINYINT(1)     NOT NULL DEFAULT 1,
  is_ai_generated  TINYINT(1)     NOT NULL DEFAULT 0,
  created_by_admin INT            NULL,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (package_id),
  INDEX idx_pkg_price    (total_price),
  INDEX idx_pkg_duration (duration_days),
  INDEX idx_pkg_category (category),
  INDEX idx_pkg_active   (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 6.2  budget_plans  (AI-generated trip budget plans)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS budget_plans (
  plan_id          INT            NOT NULL AUTO_INCREMENT,
  user_id          INT            NOT NULL,
  budget_amount    DECIMAL(12,2)  NOT NULL,
  num_travelers    INT            NOT NULL DEFAULT 1,
  duration_days    INT            NOT NULL DEFAULT 3,
  start_city       VARCHAR(100)   NULL,
  preferences      VARCHAR(500)   NULL,
  generated_plan   JSON           NULL,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (plan_id),
  CONSTRAINT fk_bp_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_bp_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 7: EMERGENCY SYSTEM
-- ============================================================================

-- --------------------------------------------------------------------------
-- 7.1  emergency_contacts  (ICE — In Case of Emergency)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS emergency_contacts (
  contact_id    INT           NOT NULL AUTO_INCREMENT,
  user_id       INT           NOT NULL,
  contact_name  VARCHAR(255)  NOT NULL,
  contact_phone VARCHAR(20)   NOT NULL,
  contact_email VARCHAR(255)  NULL,
  relationship  VARCHAR(100)  NULL,
  is_primary    TINYINT(1)    NOT NULL DEFAULT 0,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (contact_id),
  CONSTRAINT fk_ec_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_ec_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 7.2  emergency_alerts  (full in-app SOS alerts)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS emergency_alerts (
  id               INT            NOT NULL AUTO_INCREMENT,
  user_id          INT            NOT NULL,
  trip_id          INT            NULL,
  trip_type        ENUM('single','group') NULL,
  latitude         DECIMAL(10,8)  NOT NULL DEFAULT 0,
  longitude        DECIMAL(11,8)  NOT NULL DEFAULT 0,
  message          TEXT           NULL,
  status           ENUM('Active','Acknowledged','Resolved','Cancelled')
                                  NOT NULL DEFAULT 'Active',
  workflow_status  ENUM('New','Acknowledged','In Progress','Resolved')
                                  NOT NULL DEFAULT 'New',
  resolution_notes TEXT           NULL,
  acknowledged_at  TIMESTAMP      NULL DEFAULT NULL,
  in_progress_at   TIMESTAMP      NULL DEFAULT NULL,
  assigned_admin_id INT           NULL DEFAULT NULL,
  resolved_at      TIMESTAMP      NULL DEFAULT NULL,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_ea_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_ea_user_id    (user_id),
  INDEX idx_ea_status     (status),
  INDEX idx_ea_created    (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 7.3  sos_alerts  (legacy / alternate SOS table — kept for compatibility)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sos_alerts (
  id               INT            NOT NULL AUTO_INCREMENT,
  user_id          INT            NOT NULL,
  latitude         DECIMAL(10,8)  NULL,
  longitude        DECIMAL(11,8)  NULL,
  message          TEXT           NULL,
  status           ENUM('Active','Resolved','Cancelled') NOT NULL DEFAULT 'Active',
  workflow_status  ENUM('New','Acknowledged','In Progress','Resolved')
                                  NOT NULL DEFAULT 'New',
  resolution_notes TEXT           NULL,
  assigned_admin_id INT           NULL,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at      TIMESTAMP      NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_sos_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_sos_user_id (user_id),
  INDEX idx_sos_status  (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 7.4  emergency_events  (quick-dial event log — ambulance/police/tourist_police)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS emergency_events (
  id          INT            NOT NULL AUTO_INCREMENT,
  user_id     INT            NOT NULL,
  type        ENUM('ambulance','police','tourist_police','ice_share','full_sos')
                             NOT NULL,
  latitude    DECIMAL(10,8)  NULL DEFAULT NULL,
  longitude   DECIMAL(11,8)  NULL DEFAULT NULL,
  status      ENUM('Pending','Acknowledged') NOT NULL DEFAULT 'Pending',
  created_at  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_ee_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_ee_user_id (user_id),
  INDEX idx_ee_created (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 7.5  emergency_tracking  (live GPS breadcrumbs during active SOS)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS emergency_tracking (
  id           INT            NOT NULL AUTO_INCREMENT,
  emergency_id INT            NOT NULL,
  latitude     DECIMAL(10,8)  NOT NULL,
  longitude    DECIMAL(11,8)  NOT NULL,
  timestamp    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_et_alert FOREIGN KEY (emergency_id) REFERENCES emergency_alerts(id) ON DELETE CASCADE,
  INDEX idx_et_emergency (emergency_id),
  INDEX idx_et_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 8: NOTIFICATIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- 8.1  notifications
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  notification_id          INT           NOT NULL AUTO_INCREMENT,
  user_id                  INT           NOT NULL,
  title                    VARCHAR(255)  NOT NULL,
  message                  TEXT          NOT NULL,
  type                     VARCHAR(100)  NOT NULL DEFAULT 'general',
  related_route_id         INT           NULL,
  related_destination_id   INT           NULL,
  action_url               VARCHAR(500)  NULL,
  is_read                  TINYINT(1)    NOT NULL DEFAULT 0,
  created_at               TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id),
  CONSTRAINT fk_notif_user   FOREIGN KEY (user_id)               REFERENCES users(user_id)             ON DELETE CASCADE,
  CONSTRAINT fk_notif_route  FOREIGN KEY (related_route_id)      REFERENCES routes(route_id)           ON DELETE SET NULL,
  CONSTRAINT fk_notif_dest   FOREIGN KEY (related_destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_notif_user     (user_id),
  INDEX idx_notif_is_read  (is_read),
  INDEX idx_notif_created  (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 8.2  fcm_tokens  (Firebase Cloud Messaging device tokens)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fcm_tokens (
  id         INT           NOT NULL AUTO_INCREMENT,
  user_id    INT           NOT NULL,
  token      VARCHAR(512)  NOT NULL UNIQUE,
  platform   ENUM('android','ios','web') NOT NULL DEFAULT 'android',
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_fcm_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_fcm_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 9: LOCATION TRACKING
-- ============================================================================

-- --------------------------------------------------------------------------
-- 9.1  user_location_updates  (live GPS pings — anonymous or user-linked)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_location_updates (
  location_update_id   INT            NOT NULL AUTO_INCREMENT,
  user_identifier      VARCHAR(128)   NULL COMMENT 'user_id or anonymous session id',
  latitude             DECIMAL(10,8)  NOT NULL,
  longitude            DECIMAL(11,8)  NOT NULL,
  city                 VARCHAR(100)   NULL,
  country              VARCHAR(100)   NULL,
  accuracy_meters      DECIMAL(10,2)  NULL,
  captured_at          DATETIME       NOT NULL,
  created_at           TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (location_update_id),
  INDEX idx_loc_user_id    (user_identifier),
  INDEX idx_loc_captured   (captured_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 10: AI & RECOMMENDATIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- 10.1  ai_chat_history  (travel AI chatbot)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai_chat_history (
  chat_id          INT       NOT NULL AUTO_INCREMENT,
  user_id          INT       NOT NULL,
  user_message     TEXT      NOT NULL,
  ai_response      TEXT      NOT NULL,
  context_data     JSON      NULL,
  helpful_rating   INT       NULL CHECK (helpful_rating BETWEEN 1 AND 5),
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chat_id),
  CONSTRAINT fk_ai_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_ai_user    (user_id),
  INDEX idx_ai_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 10.2  mental_health_chat_history  (wellness / travel anxiety chatbot)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mental_health_chat_history (
  id           INT       NOT NULL AUTO_INCREMENT,
  user_id      INT       NOT NULL,
  user_message TEXT      NOT NULL,
  ai_response  TEXT      NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_mh_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_mh_user_time (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 10.3  ai_recommendations
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai_recommendations (
  recommendation_id      INT            NOT NULL AUTO_INCREMENT,
  user_id                INT            NOT NULL,
  destination_id         INT            NULL,
  reason                 TEXT           NULL,
  confidence_score       DECIMAL(3,2)   NULL,
  recommended_visit_date DATE           NULL,
  viewed                 TINYINT(1)     NOT NULL DEFAULT 0,
  created_at             TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (recommendation_id),
  CONSTRAINT fk_airec_user FOREIGN KEY (user_id)       REFERENCES users(user_id)             ON DELETE CASCADE,
  CONSTRAINT fk_airec_dest FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  INDEX idx_airec_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 11: VIRTUAL TOURS
-- ============================================================================

-- --------------------------------------------------------------------------
-- 11.1  virtual_tours
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS virtual_tours (
  id              INT           NOT NULL AUTO_INCREMENT,
  destination_id  INT           NULL,
  title           VARCHAR(255)  NOT NULL,
  description     TEXT          NULL,
  thumbnail_url   VARCHAR(500)  NULL,
  is_active       TINYINT(1)    NOT NULL DEFAULT 1,
  created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_vt_dest FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_vt_destination (destination_id),
  INDEX idx_vt_active      (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 11.2  virtual_tour_scenes
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS virtual_tour_scenes (
  id            INT           NOT NULL AUTO_INCREMENT,
  tour_id       INT           NOT NULL,
  scene_name    VARCHAR(255)  NOT NULL,
  panorama_url  VARCHAR(500)  NOT NULL COMMENT 'equirectangular image URL',
  thumbnail_url VARCHAR(500)  NULL,
  description   TEXT          NULL,
  ai_narration  TEXT          NULL,
  scene_order   INT           NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT fk_vts_tour FOREIGN KEY (tour_id) REFERENCES virtual_tours(id) ON DELETE CASCADE,
  INDEX idx_vts_tour (tour_id, scene_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 11.3  virtual_tour_hotspots
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS virtual_tour_hotspots (
  id              INT     NOT NULL AUTO_INCREMENT,
  scene_id        INT     NOT NULL,
  type            ENUM('scene','info') NOT NULL DEFAULT 'info',
  target_scene_id INT     NULL COMMENT 'Points to another scene for navigation hotspots',
  title           VARCHAR(255) NULL,
  text            TEXT    NULL,
  pitch           FLOAT   NOT NULL DEFAULT 0,
  yaw             FLOAT   NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT fk_vth_scene  FOREIGN KEY (scene_id)        REFERENCES virtual_tour_scenes(id) ON DELETE CASCADE,
  CONSTRAINT fk_vth_target FOREIGN KEY (target_scene_id) REFERENCES virtual_tour_scenes(id) ON DELETE SET NULL,
  INDEX idx_vth_scene (scene_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 12: ADMIN TABLES
-- ============================================================================

-- --------------------------------------------------------------------------
-- 12.1  admin_activity_logs
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_activity_logs (
  id          INT           NOT NULL AUTO_INCREMENT,
  admin_id    INT           NOT NULL COMMENT 'admins.admin_id',
  admin_name  VARCHAR(255)  NOT NULL DEFAULT '',
  action      VARCHAR(100)  NOT NULL,
  target_type VARCHAR(50)   NULL,
  target_id   INT           NULL,
  details     TEXT          NULL,
  ip_address  VARCHAR(45)   NULL,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_aal_admin   (admin_id),
  INDEX idx_aal_created (created_at),
  INDEX idx_aal_action  (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------------
-- 12.2  admin_logs  (general admin action log — from migration v2)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_logs (
  log_id      INT           NOT NULL AUTO_INCREMENT,
  admin_id    INT           NOT NULL COMMENT 'users.user_id for is_admin=1 users',
  action      VARCHAR(100)  NOT NULL,
  target_type VARCHAR(50)   NULL,
  target_id   INT           NULL,
  details     JSON          NULL,
  ip_address  VARCHAR(45)   NULL,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (log_id),
  CONSTRAINT fk_alog_admin FOREIGN KEY (admin_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_alog_admin   (admin_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 13: LEGACY COMPATIBILITY TABLES
-- (Kept to avoid breaking any old code paths. Do not use in new development.)
-- ============================================================================

-- --------------------------------------------------------------------------
-- 13.1  Traveler  (legacy user table — replaced by users)
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Traveler (
  userId                   INT           NOT NULL AUTO_INCREMENT,
  email                    VARCHAR(255)  NOT NULL UNIQUE,
  passwordHash             VARCHAR(255)  NOT NULL,
  name                     VARCHAR(255)  NULL,
  phoneNumber              VARCHAR(20)   NULL,
  bloodGroup               VARCHAR(10)   NULL,
  lastLocation             VARCHAR(255)  NULL,
  last_location            VARCHAR(255)  NULL,
  last_latitude            DECIMAL(10,8) NULL,
  last_longitude           DECIMAL(11,8) NULL,
  lastLocationUpdatedAt    DATETIME      NULL,
  last_location_updated_at DATETIME      NULL,
  created_at               TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at               TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (userId),
  INDEX idx_traveler_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 14: ALTER EXISTING TABLES
-- (Safely add missing columns to tables that may already exist)
-- ============================================================================

-- users — add new columns if missing
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS firebase_uid           VARCHAR(128)  NULL AFTER user_id,
  ADD COLUMN IF NOT EXISTS is_admin               TINYINT(1)    NOT NULL DEFAULT 0 AFTER is_active,
  ADD COLUMN IF NOT EXISTS is_blocked             TINYINT(1)    NOT NULL DEFAULT 0 AFTER is_admin,
  ADD COLUMN IF NOT EXISTS blood_group            VARCHAR(10)   NULL AFTER bio,
  ADD COLUMN IF NOT EXISTS suspended_at           TIMESTAMP     NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS suspended_reason       VARCHAR(500)  NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS last_login_at          TIMESTAMP     NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS theme_preference       VARCHAR(20)   NOT NULL DEFAULT 'default',
  ADD COLUMN IF NOT EXISTS updated_at             TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP;

-- emergency_contacts — add email column if missing
ALTER TABLE emergency_contacts
  ADD COLUMN IF NOT EXISTS contact_email VARCHAR(255) NULL AFTER contact_phone;

-- user_preferences — ensure unique constraint
ALTER TABLE user_preferences
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP;

-- bookings — add all lifecycle columns if they somehow pre-existed without them
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS travel_date         DATE           NULL AFTER booking_date,
  ADD COLUMN IF NOT EXISTS num_travelers        INT            NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS package_id          INT            NULL,
  ADD COLUMN IF NOT EXISTS total_amount        DECIMAL(10,2)  NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_status      ENUM('Unpaid','Paid','Refunded') NOT NULL DEFAULT 'Unpaid',
  ADD COLUMN IF NOT EXISTS payment_intent_id   VARCHAR(255)   NULL,
  ADD COLUMN IF NOT EXISTS cancelled_at        TIMESTAMP      NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT           NULL,
  ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP;

-- group_bookings — add extra columns
ALTER TABLE group_bookings
  ADD COLUMN IF NOT EXISTS max_members    INT            NOT NULL DEFAULT 20,
  ADD COLUMN IF NOT EXISTS destination_id INT            NULL,
  ADD COLUMN IF NOT EXISTS total_amount   DECIMAL(10,2)  NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_type   ENUM('individual','full') NOT NULL DEFAULT 'individual',
  ADD COLUMN IF NOT EXISTS updated_at     TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP;

-- group_booking_members — add role
ALTER TABLE group_booking_members
  ADD COLUMN IF NOT EXISTS role ENUM('organizer','member') NOT NULL DEFAULT 'member';

-- payments — add refund columns
ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS refund_requested_at TIMESTAMP    NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS refund_approved_at  TIMESTAMP    NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS refund_rejected_at  TIMESTAMP    NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS refund_admin_notes  VARCHAR(500) NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS group_booking_id    INT          NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMP    NULL ON UPDATE CURRENT_TIMESTAMP;

-- emergency_alerts — add workflow columns
ALTER TABLE emergency_alerts
  ADD COLUMN IF NOT EXISTS workflow_status   ENUM('New','Acknowledged','In Progress','Resolved') NOT NULL DEFAULT 'New',
  ADD COLUMN IF NOT EXISTS resolution_notes  TEXT      NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS acknowledged_at   TIMESTAMP NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS in_progress_at    TIMESTAMP NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS assigned_admin_id INT       NULL DEFAULT NULL;

-- sos_alerts — add workflow columns
ALTER TABLE sos_alerts
  ADD COLUMN IF NOT EXISTS workflow_status   ENUM('New','Acknowledged','In Progress','Resolved') NOT NULL DEFAULT 'New',
  ADD COLUMN IF NOT EXISTS resolution_notes  TEXT NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS assigned_admin_id INT  NULL DEFAULT NULL;

-- destinations — ensure average_cost exists
ALTER TABLE destinations
  ADD COLUMN IF NOT EXISTS average_cost DECIMAL(10,2) NULL DEFAULT NULL;

-- notifications — ensure type column exists
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS type VARCHAR(100) NOT NULL DEFAULT 'general';

-- tour_packages — ensure price_per_day column exists
ALTER TABLE tour_packages
  ADD COLUMN IF NOT EXISTS price_per_day DECIMAL(10,2) NOT NULL DEFAULT 50.00;

-- ============================================================================
-- SECTION 15: PERFORMANCE INDEXES
-- (CREATE INDEX IF NOT EXISTS is idempotent in MySQL 8+)
-- ============================================================================

-- bookings
CREATE INDEX IF NOT EXISTS idx_booking_created  ON bookings (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_booking_user_stat ON bookings (user_id, status);

-- payments
CREATE INDEX IF NOT EXISTS idx_pay_created       ON payments (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pay_refund_pend   ON payments (refund_requested_at);

-- emergency
CREATE INDEX IF NOT EXISTS idx_ea_user_active    ON emergency_alerts (user_id, status);
CREATE INDEX IF NOT EXISTS idx_ee_type           ON emergency_events (type);

-- group bookings
CREATE INDEX IF NOT EXISTS idx_gb_dates          ON group_bookings (start_date, end_date);

-- tracking
CREATE INDEX IF NOT EXISTS idx_loc_lat_lng       ON user_location_updates (latitude, longitude);

-- virtual tours
CREATE INDEX IF NOT EXISTS idx_vt_active_dest    ON virtual_tours (is_active, destination_id);

-- notifications
CREATE INDEX IF NOT EXISTS idx_notif_unread      ON notifications (user_id, is_read, created_at DESC);

-- users
CREATE INDEX IF NOT EXISTS idx_users_firebase    ON users (firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_blocked     ON users (is_blocked);

-- ============================================================================
-- SECTION 16: SQL VIEWS
-- ============================================================================

-- --------------------------------------------------------------------------
-- 16.1  booking_summary_view
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW booking_summary_view AS
SELECT
  b.booking_id,
  b.user_id,
  u.full_name          AS user_name,
  u.email              AS user_email,
  d.name               AS destination_name,
  d.city,
  b.travel_date,
  b.num_travelers,
  b.total_amount,
  b.status,
  b.payment_status,
  b.created_at
FROM bookings b
JOIN users u        ON b.user_id        = u.user_id
JOIN destinations d ON b.destination_id = d.destination_id;

-- --------------------------------------------------------------------------
-- 16.2  payment_summary_view
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW payment_summary_view AS
SELECT
  p.id                 AS payment_id,
  p.user_id,
  u.full_name          AS user_name,
  u.email              AS user_email,
  p.amount,
  p.currency,
  p.status,
  p.stripe_payment_intent_id,
  b.booking_id,
  d.name               AS destination_name,
  p.refund_requested_at,
  p.refund_approved_at,
  p.refund_rejected_at,
  p.created_at
FROM payments p
JOIN users u                ON p.user_id   = u.user_id
LEFT JOIN bookings b        ON p.booking_id = b.booking_id
LEFT JOIN destinations d    ON b.destination_id = d.destination_id;

-- --------------------------------------------------------------------------
-- 16.3  emergency_summary_view
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW emergency_summary_view AS
SELECT
  ea.id                AS alert_id,
  ea.user_id,
  u.full_name          AS user_name,
  u.phone_number,
  u.email,
  ea.latitude,
  ea.longitude,
  ea.message,
  ea.status,
  ea.workflow_status,
  ea.created_at,
  ea.resolved_at,
  (
    SELECT COUNT(*) FROM emergency_tracking et WHERE et.emergency_id = ea.id
  )                    AS tracking_points
FROM emergency_alerts ea
JOIN users u ON ea.user_id = u.user_id;

-- --------------------------------------------------------------------------
-- 16.4  user_activity_view
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW user_activity_view AS
SELECT
  u.user_id,
  u.full_name,
  u.email,
  u.created_at                                       AS joined_at,
  u.last_login_at,
  COUNT(DISTINCT b.booking_id)                       AS total_bookings,
  COUNT(DISTINCT gb.group_booking_id)                AS group_trips,
  COUNT(DISTINCT ea.id)                              AS sos_alerts,
  COUNT(DISTINCT p.id)                               AS total_payments,
  COALESCE(SUM(p.amount), 0)                         AS total_spent
FROM users u
LEFT JOIN bookings b           ON b.user_id         = u.user_id
LEFT JOIN group_booking_members gbm ON gbm.user_id  = u.user_id
LEFT JOIN group_bookings gb    ON gb.group_booking_id = gbm.group_booking_id
LEFT JOIN emergency_alerts ea  ON ea.user_id         = u.user_id
LEFT JOIN payments p           ON p.user_id          = u.user_id AND p.status = 'succeeded'
GROUP BY u.user_id, u.full_name, u.email, u.created_at, u.last_login_at;

-- ============================================================================
-- SECTION 17: STORED PROCEDURES
-- ============================================================================

-- Drop and recreate procedures safely
DROP PROCEDURE IF EXISTS CreateBooking;
DROP PROCEDURE IF EXISTS TriggerSOS;
DROP PROCEDURE IF EXISTS CreatePayment;
DROP PROCEDURE IF EXISTS GenerateMonthlyReport;

DELIMITER $$

-- --------------------------------------------------------------------------
-- 17.1  CreateBooking
-- --------------------------------------------------------------------------
CREATE PROCEDURE CreateBooking(
  IN  p_user_id         INT,
  IN  p_destination_id  INT,
  IN  p_travel_date     DATE,
  IN  p_num_travelers   INT,
  IN  p_duration_days   INT,
  IN  p_total_amount    DECIMAL(10,2),
  IN  p_notes           TEXT,
  OUT p_booking_id      INT
)
BEGIN
  INSERT INTO bookings
    (user_id, destination_id, booking_date, travel_date, num_travelers,
     estimated_duration_days, total_amount, notes, status, payment_status)
  VALUES
    (p_user_id, p_destination_id, CURDATE(), p_travel_date, p_num_travelers,
     p_duration_days, p_total_amount, p_notes, 'Pending', 'Unpaid');

  SET p_booking_id = LAST_INSERT_ID();
END$$

-- --------------------------------------------------------------------------
-- 17.2  TriggerSOS
-- --------------------------------------------------------------------------
CREATE PROCEDURE TriggerSOS(
  IN  p_user_id   INT,
  IN  p_latitude  DECIMAL(10,8),
  IN  p_longitude DECIMAL(11,8),
  IN  p_message   TEXT,
  OUT p_alert_id  INT
)
BEGIN
  INSERT INTO emergency_alerts
    (user_id, latitude, longitude, message, status, workflow_status)
  VALUES
    (p_user_id, p_latitude, p_longitude, p_message, 'Active', 'New');

  SET p_alert_id = LAST_INSERT_ID();

  INSERT INTO emergency_events (user_id, type, latitude, longitude)
  VALUES (p_user_id, 'full_sos', p_latitude, p_longitude);

  INSERT INTO notifications (user_id, title, message, type)
  VALUES (
    p_user_id,
    'SOS Alert Sent',
    'Your emergency alert has been broadcast. Help is on the way.',
    'emergency_sos_sent'
  );
END$$

-- --------------------------------------------------------------------------
-- 17.3  CreatePayment
-- --------------------------------------------------------------------------
CREATE PROCEDURE CreatePayment(
  IN  p_user_id     INT,
  IN  p_booking_id  INT,
  IN  p_amount      DECIMAL(10,2),
  IN  p_intent_id   VARCHAR(255),
  OUT p_payment_id  INT
)
BEGIN
  INSERT INTO payments
    (user_id, booking_id, stripe_payment_intent_id, amount, currency, status)
  VALUES
    (p_user_id, p_booking_id, p_intent_id, p_amount, 'usd', 'pending')
  ON DUPLICATE KEY UPDATE status = 'pending', updated_at = CURRENT_TIMESTAMP;

  SET p_payment_id = LAST_INSERT_ID();
END$$

-- --------------------------------------------------------------------------
-- 17.4  GenerateMonthlyReport  (returns booking + revenue stats for a month)
-- --------------------------------------------------------------------------
CREATE PROCEDURE GenerateMonthlyReport(
  IN p_year  INT,
  IN p_month INT
)
BEGIN
  SELECT
    COUNT(*)                                          AS total_bookings,
    SUM(CASE WHEN status='Confirmed'  THEN 1 ELSE 0 END) AS confirmed,
    SUM(CASE WHEN status='Completed'  THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN status='Cancelled'  THEN 1 ELSE 0 END) AS cancelled,
    COALESCE(SUM(CASE WHEN payment_status='Paid' THEN total_amount ELSE 0 END), 0) AS total_revenue
  FROM bookings
  WHERE YEAR(created_at) = p_year AND MONTH(created_at) = p_month;
END$$

DELIMITER ;

-- ============================================================================
-- SECTION 18: SEED DATA
-- ============================================================================

-- --------------------------------------------------------------------------
-- 18.1  Default admin account
--       Password: Admin@SafarSync2025! (bcrypt hash below)
--       CHANGE THIS IMMEDIATELY after first login.
-- --------------------------------------------------------------------------
INSERT IGNORE INTO admins (email, password_hash, full_name, role)
VALUES (
  'admin@safarsync.com',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TqrCJxqLkQJHwPxMhkNPFVKdYXvy',
  'SafarSync Admin',
  'super_admin'
);

-- --------------------------------------------------------------------------
-- 18.2  Emergency Services (reference data — not linked to a real user)
-- --------------------------------------------------------------------------
-- These are reference records only; the app uses hardcoded numbers + the
-- emergency_events table for logging. No FK on user_id here.

-- --------------------------------------------------------------------------
-- 18.3  Default tour packages (Sasta Tours)
-- --------------------------------------------------------------------------
INSERT IGNORE INTO tour_packages
  (package_id, title, description, duration_days, total_price, price_per_day, category, destinations, itinerary, includes, image_url, is_active)
VALUES
(1, 'Weekend Escape — Murree & Nathiagali',
  'A short 3-day getaway to the cool hills of Murree and Nathiagali.',
  3, 15000.00, 5000.00, 'Nature',
  '["Murree","Nathiagali","Patriata"]',
  '[{"day":1,"title":"Arrival + Murree Mall Road","desc":"Check in, evening stroll on Mall Road"},{"day":2,"title":"Nathiagali Hike","desc":"Morning hike to Miranjani top"},{"day":3,"title":"Patriata Chair Lift + Return","desc":"Chair lift ride, depart by evening"}]',
  '["Hotel 2 nights","Breakfast & dinner","Local guide","Chair lift tickets"]',
  NULL, 1),

(2, 'Adventure Week — Hunza Valley',
  'Explore the breathtaking Hunza Valley over 7 days.',
  7, 35000.00, 5000.00, 'Adventure',
  '["Hunza","Karimabad","Attabad Lake","Passu"]',
  '[{"day":1,"title":"Islamabad → Hunza (Flight)","desc":"Fly to Gilgit, drive to Hunza"},{"day":2,"title":"Baltit Fort & Karimabad","desc":"Historic fort tour, local bazaar"},{"day":3,"title":"Attabad Lake","desc":"Boat ride on the stunning blue lake"},{"day":4,"title":"Passu Cones Trek","desc":"Day hike to iconic Passu Cathedral"},{"day":5,"title":"Eagle Nest Viewpoint","desc":"Panoramic views at sunrise"},{"day":6,"title":"Local Culture Day","desc":"Apricot farm, local food, music"},{"day":7,"title":"Return Flight","desc":"Back to Islamabad"}]',
  '["Hotel 6 nights","All meals","Flight Islamabad↔Gilgit","Local guide","Boat ride","Transport"]',
  NULL, 1),

(3, 'Grand Pakistan Explorer — 14 Days',
  'The ultimate Pakistan road trip covering Lahore, Islamabad, Naran, Swat, and Hunza.',
  14, 55000.00, 3929.00, 'Cultural',
  '["Lahore","Islamabad","Naran Valley","Swat","Hunza"]',
  '[{"day":1,"title":"Lahore — Walled City","desc":"Badshahi Mosque, Lahore Fort, Food Street"},{"day":2,"title":"Lahore — Museums","desc":"Pakistan Museum, Shalimar Gardens"},{"day":3,"title":"Lahore → Islamabad","desc":"Motorway drive, Faisal Mosque"},{"day":4,"title":"Islamabad & Margalla Hills","desc":"Trail 5 hike, Daman-e-Koh"},{"day":5,"title":"Islamabad → Naran","desc":"Scenic KKH drive"},{"day":6,"title":"Naran — Saif ul Malook","desc":"Lake visit by jeep"},{"day":7,"title":"Naran → Swat","desc":"Transfer through scenic passes"},{"day":8,"title":"Swat Valley","desc":"Fizagat Park, White Palace"},{"day":9,"title":"Swat → Mingora","desc":"Malam Jabba ski resort area"},{"day":10,"title":"Swat → Gilgit","desc":"Long drive through KKH"},{"day":11,"title":"Hunza Arrival","desc":"Rest, Karimabad evening walk"},{"day":12,"title":"Hunza Highlights","desc":"Baltit Fort, Attabad Lake"},{"day":13,"title":"Hunza — Eagle Nest","desc":"Sunrise viewpoint"},{"day":14,"title":"Return Flight","desc":"Gilgit → Islamabad"}]',
  '["Hotel 13 nights","All meals","Transport throughout","Local guides","Entry tickets","Jeep rides"]',
  NULL, 1),

(4, 'Family Fun — Swat Valley',
  'A 5-day family holiday in the lush Swat Valley.',
  5, 22000.00, 4400.00, 'Nature',
  '["Swat","Mingora","Malam Jabba","Fizagat"]',
  '[{"day":1,"title":"Arrival Mingora","desc":"Check in, Swat Museum visit"},{"day":2,"title":"Malam Jabba","desc":"Chair lift + scenic meadows"},{"day":3,"title":"Fizagat Park & River","desc":"Picnic by the river, kids activities"},{"day":4,"title":"Waterfalls Day","desc":"Visit local waterfalls and farms"},{"day":5,"title":"Shopping & Departure","desc":"Swati handicrafts, return home"}]',
  '["Hotel 4 nights","Breakfast","Chair lift tickets","Guide","Transport"]',
  NULL, 1),

(5, 'Budget City Break — Lahore',
  'Explore the cultural heart of Pakistan in just 2 days.',
  2, 8000.00, 4000.00, 'Cultural',
  '["Lahore","Anarkali","Wagah Border"]',
  '[{"day":1,"title":"Old Lahore","desc":"Badshahi Mosque, Lahore Fort, Anarkali Bazaar, Food Street"},{"day":2,"title":"Wagah Border + Gardens","desc":"Shalimar Gardens, Wagah Border ceremony at sunset"}]',
  '["Hotel 1 night","Breakfast","Wagah Border transport","Guide"]',
  NULL, 1);

-- --------------------------------------------------------------------------
-- 18.4  Virtual Tour seed data (demo panoramas using Wikimedia images)
-- --------------------------------------------------------------------------
INSERT IGNORE INTO virtual_tours (id, destination_id, title, description, thumbnail_url, is_active) VALUES
(1, NULL, 'Hunza Valley Tour',    'Explore the breathtaking Hunza Valley across 4 iconic locations.', NULL, 1),
(2, NULL, 'Lahore Heritage Tour', 'Walk through 400 years of Mughal history in Lahore.', NULL, 1),
(3, NULL, 'Skardu Adventure Tour','Experience the cold desert and turquoise lakes of Skardu.', NULL, 1);

INSERT IGNORE INTO virtual_tour_scenes
  (id, tour_id, scene_name, panorama_url, description, scene_order) VALUES
-- Hunza
(1,  1, 'Attabad Lake',   'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Attabad_Lake_Hunza_2.jpg/2560px-Attabad_Lake_Hunza_2.jpg', 'A turquoise lake formed by the 2010 Attabad landslide.', 0),
(2,  1, 'Baltit Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Baltit_fort.jpg/2560px-Baltit_fort.jpg',                   'A 700-year-old fort overlooking Karimabad.', 1),
(3,  1, 'Eagle Nest View','https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Hunza_Valley_from_Eagle%27s_Nest.jpg/2560px-Hunza_Valley_from_Eagle%27s_Nest.jpg', 'The highest viewpoint in Hunza.', 2),
(4,  1, 'Passu Cones',    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Passu_Cones_%282%29.jpg/2560px-Passu_Cones_%282%29.jpg',   'Cathedral-like spires in the Karakoram.', 3),
-- Lahore
(5,  2, 'Badshahi Mosque','https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Badshahi_Mosque_July_1_2005_pic32_by_Ali_Imran.jpg/2560px-Badshahi_Mosque_July_1_2005_pic32_by_Ali_Imran.jpg', 'One of the world largest mosques.', 0),
(6,  2, 'Lahore Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Lahore_Fort_Sheesh_Mahal.jpg/2560px-Lahore_Fort_Sheesh_Mahal.jpg', 'UNESCO World Heritage Site.', 1),
(7,  2, 'Walled City',   'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Old_Lahore.jpg/2560px-Old_Lahore.jpg',                      'Ancient walled city of Lahore.', 2),
-- Skardu
(8,  3, 'Shangrila Lake', 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Shangrila_Resort_Kachura_Lake_Skardu.jpg/2560px-Shangrila_Resort_Kachura_Lake_Skardu.jpg', 'Heaven on Earth at 2,500m altitude.', 0),
(9,  3, 'Deosai Plains',  'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Deosai_National_Park.jpg/2560px-Deosai_National_Park.jpg',   'One of the world highest plateaus.', 1),
(10, 3, 'Shigar Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Shigar_Fort.JPG/1280px-Shigar_Fort.JPG',                     '400-year-old restored palace fort.', 2);

INSERT IGNORE INTO virtual_tour_hotspots
  (scene_id, type, target_scene_id, title, text, pitch, yaw) VALUES
-- Hunza Tour navigation
(1, 'scene', 2,  'Go to Baltit Fort',   NULL, -5,  45),
(1, 'info',  NULL,'Attabad Lake',        'Formed in 2010 when a landslide blocked the Hunza River. 21km long, 100m deep.', 10, -90),
(2, 'scene', 3,  'Eagle Nest View',      NULL, -3, 120),
(2, 'scene', 1,  'Back to Attabad',      NULL, -3, -60),
(3, 'scene', 4,  'Passu Cones',          NULL, -5,  90),
(3, 'scene', 2,  'Back to Baltit',       NULL, -5, -90),
(4, 'scene', 1,  'Back to Attabad',      NULL, -5, 180),
-- Lahore Tour navigation
(5, 'scene', 6,  'Go to Lahore Fort',    NULL, -5,  60),
(6, 'scene', 7,  'Walled City',          NULL, -5, 180),
(6, 'scene', 5,  'Back to Mosque',       NULL, -5,   0),
(7, 'scene', 5,  'Back to Mosque',       NULL, -5,   0),
-- Skardu Tour navigation
(8,  'scene', 9,  'Deosai Plains',       NULL, -5,  90),
(9,  'scene', 10, 'Shigar Fort',         NULL, -5, 180),
(9,  'scene', 8,  'Back to Shangrila',   NULL, -5,   0),
(10, 'scene', 8,  'Back to Shangrila',   NULL, -5,  90);

-- ============================================================================
-- SECTION 19: VERIFICATION QUERY
-- (Run this after import to confirm all tables exist)
-- ============================================================================

SELECT
  table_name       AS `Table`,
  table_rows       AS `Est. Rows`,
  ROUND((data_length + index_length) / 1024, 1) AS `Size KB`
FROM information_schema.tables
WHERE table_schema = 'safarsync'
ORDER BY table_name;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
-- Total new tables created   : 30+
-- Total tables altered       : 10
-- Total indexes              : 50+
-- Total views                : 4
-- Total stored procedures    : 4
-- Total seed records         : admins(1) + tour_packages(5) + virtual_tours(3)
--                              + scenes(10) + hotspots(15)
-- ============================================================================
