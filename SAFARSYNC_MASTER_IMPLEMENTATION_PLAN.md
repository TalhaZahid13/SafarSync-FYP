# SAFARSYNC MASTER IMPLEMENTATION PLAN
## Complete Production-Grade Blueprint

**Status:** Active Development  
**Version:** 1.0 - Master Plan  
**Last Updated:** June 12, 2026  
**Target Completion:** September 12, 2026 (3 months)  

---

# TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Complete Database Schema](#complete-database-schema)
4. [Complete API Specification](#complete-api-specification)
5. [Frontend Screen Architecture](#frontend-screen-architecture)
6. [Admin Dashboard Architecture](#admin-dashboard-architecture)
7. [AI & Safety Engine Design](#ai--safety-engine-design)
8. [Security Implementation Plan](#security-implementation-plan)
9. [Development Roadmap](#development-roadmap)
10. [Phase-by-Phase Implementation Guide](#phase-by-phase-implementation-guide)

---

# EXECUTIVE SUMMARY

## Current State
- **Feature Completion:** 28%
- **Security Score:** 15%
- **Architecture:** Solid foundation with critical gaps
- **Time to Production:** 60-90 days

## Transformation Plan
This master plan outlines the complete transformation of SafarSync from 28% to 100% completion.

**Key Deliverables:**
- 13 Complete Modules
- 40+ Backend APIs
- 35+ Flutter Screens
- 10+ Admin Dashboard Screens
- Enterprise-Grade Security
- AI-Powered Safety System
- Mental Health Integration
- Payment Processing

**Investment:** 1,500-2,000 developer hours (3-person team, 3 months)

---

# SYSTEM ARCHITECTURE

## 1. High-Level Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     SAFARSYNC ECOSYSTEM                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐         ┌──────────────┐      ┌────────────┐ │
│  │   Mobile    │         │    Web       │      │   Admin    │ │
│  │  (Flutter)  │         │  Dashboard   │      │ Dashboard  │ │
│  └──────┬──────┘         └──────┬───────┘      └─────┬──────┘ │
│         │                       │                    │        │
│         └───────────────────────┼────────────────────┘        │
│                                 │                            │
│         ┌───────────────────────▼────────────────────┐       │
│         │  API Gateway & Load Balancer              │       │
│         │  (Rate Limiting, CORS, Auth)             │       │
│         └───────────────────────┬────────────────────┘       │
│                                 │                            │
│  ┌──────────────────────────────┴──────────────────────────┐ │
│  │               BACKEND SERVICES LAYER                    │ │
│  ├──────────────────────────────────────────────────────────┤ │
│  │                                                          │ │
│  │  ┌────────────┐  ┌─────────────┐  ┌──────────────┐     │ │
│  │  │   Auth     │  │   User      │  │   Trip       │     │ │
│  │  │  Service   │  │  Service    │  │  Service     │     │ │
│  │  └────────────┘  └─────────────┘  └──────────────┘     │ │
│  │                                                          │ │
│  │  ┌────────────┐  ┌─────────────┐  ┌──────────────┐     │ │
│  │  │  Location  │  │   Safety    │  │    Payment   │     │ │
│  │  │  Service   │  │   Service   │  │    Service   │     │ │
│  │  └────────────┘  └─────────────┘  └──────────────┘     │ │
│  │                                                          │ │
│  │  ┌────────────┐  ┌─────────────┐  ┌──────────────┐     │ │
│  │  │    AI      │  │   Mental    │  │ Notification │     │ │
│  │  │  Service   │  │   Health    │  │   Service    │     │ │
│  │  └────────────┘  └─────────────┘  └──────────────┘     │ │
│  │                                                          │ │
│  └──────────────────────────────┬───────────────────────────┘ │
│                                 │                            │
│  ┌──────────────────────────────┴──────────────────────────┐ │
│  │            DATA & INTEGRATION LAYER                    │ │
│  ├──────────────────────────────────────────────────────────┤ │
│  │                                                          │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │ │
│  │  │  MySQL   │  │ Firebase │  │   Cache  │  │  File  │  │ │
│  │  │          │  │          │  │ (Redis)  │  │Storage │  │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └────────┘  │ │
│  │                                                          │ │
│  │  ┌────────────────┐  ┌─────────────────┐              │ │
│  │  │  OpenWeather   │  │  Stripe/Razorpay│              │ │
│  │  │      API       │  │   Payment API   │              │ │
│  │  └────────────────┘  └─────────────────┘              │ │
│  │                                                          │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 2. Technology Stack (Confirmed)

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.x | iOS, Android, Web |
| **Backend** | Node.js 18+ | Express.js REST API |
| **Database** | MySQL 8.0 | Relational data |
| **Real-Time** | Socket.io 4.x | Live tracking, notifications |
| **Cloud** | Firebase | Auth, Analytics, Cloud Messaging |
| **Cache** | Redis | Session, rate limiting |
| **File Storage** | Firebase Storage | Images, documents |
| **AI** | Groq (Llama 3.3) | Travel Assistant |
| **Weather** | OpenWeatherMap | Weather forecasting |
| **Payments** | Stripe/Razorpay | Payment processing |
| **Authentication** | JWT + MFA | Security |

## 3. Service Layer Architecture

```
SERVICE LAYER ORGANIZATION:

AuthService/
├── registration
├── login
├── emailVerification
├── passwordReset
├── mfaSetup
├── tokenRefresh
└── sessionManagement

UserService/
├── profileManagement
├── preferenceManagement
├── emergencyContactManagement
└── accessibilitySettings

TripService/
├── tripManagement
├── participantManagement
├── itineraryPlanning
├── tripTracking
└── tripExpenses

LocationService/
├── liveTracking
├── locationHistory
├── geofencing
├── proximityAlerts
└── routeTracking

SafetyService/
├── riskAssessment
├── emergencyHandling
├── sosActivation
├── incidentReporting
└── safetyAlerts

PaymentService/
├── paymentProcessing
├── bookingManagement
├── transactionHistory
├── refundProcessing
└── invoiceGeneration

AIService/
├── travelAssistant
├── recommendations
├── weatherInsights
├── safetyAdvisory
└── contextAwareness

MentalHealthService/
├── wellnessChat
├── moodTracking
├── dailyCheckIns
├── crisisSupport
└── chatHistory

NotificationService/
├── pushNotifications
├── emailNotifications
├── smsNotifications
├── inAppNotifications
└── notificationScheduling

AnalyticsService/
├── eventTracking
├── usageMetrics
├── dashboardData
└── reportGeneration
```

---

# COMPLETE DATABASE SCHEMA

## 1. Core Tables (Existing - Keep & Expand)

### users (Expand from current)
```sql
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone_number VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  profile_picture_url VARCHAR(500),
  gender ENUM('Male', 'Female', 'Non-Binary', 'Prefer Not to Say'),
  date_of_birth DATE,
  blood_group VARCHAR(10),
  medical_conditions TEXT,
  allergies TEXT,
  bio TEXT,
  travel_style ENUM('Adventure', 'Luxury', 'Budget', 'Mix'),
  budget_range ENUM('Low', 'Medium', 'High', 'Flexible'),
  interests JSON,
  accessibility_needs JSON,
  role_id INT NOT NULL DEFAULT 1,
  is_email_verified BOOLEAN DEFAULT FALSE,
  email_verified_at TIMESTAMP NULL,
  is_phone_verified BOOLEAN DEFAULT FALSE,
  phone_verified_at TIMESTAMP NULL,
  is_active BOOLEAN DEFAULT TRUE,
  is_banned BOOLEAN DEFAULT FALSE,
  ban_reason VARCHAR(500),
  last_login TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (role_id) REFERENCES roles(role_id),
  INDEX idx_email (email),
  INDEX idx_phone_number (phone_number),
  INDEX idx_role_id (role_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### roles (New)
```sql
CREATE TABLE roles (
  role_id INT AUTO_INCREMENT PRIMARY KEY,
  role_name ENUM('Traveler', 'Organizer', 'Admin') NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_role_name (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### permissions (New)
```sql
CREATE TABLE permissions (
  permission_id INT AUTO_INCREMENT PRIMARY KEY,
  permission_name VARCHAR(100) UNIQUE NOT NULL,
  description VARCHAR(255),
  resource VARCHAR(100),
  action VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_permission_name (permission_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### role_permissions (New)
```sql
CREATE TABLE role_permissions (
  role_id INT NOT NULL,
  permission_id INT NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
  FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE,
  INDEX idx_role_id (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### emergency_contacts (Expand from current)
```sql
CREATE TABLE emergency_contacts (
  contact_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  contact_name VARCHAR(255) NOT NULL,
  contact_phone VARCHAR(20) NOT NULL,
  relationship VARCHAR(100),
  email VARCHAR(255),
  is_primary BOOLEAN DEFAULT FALSE,
  notify_on_sos BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_is_primary (is_primary)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 2. New Core Tables

### trips (New - Core)
```sql
CREATE TABLE trips (
  trip_id INT AUTO_INCREMENT PRIMARY KEY,
  organizer_id INT NOT NULL,
  trip_name VARCHAR(255) NOT NULL,
  description TEXT,
  status ENUM('Planned', 'Active', 'Completed', 'Cancelled') DEFAULT 'Planned',
  start_date DATETIME NOT NULL,
  end_date DATETIME NOT NULL,
  duration_days INT,
  destination_primary VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  is_group_trip BOOLEAN DEFAULT TRUE,
  max_participants INT DEFAULT 10,
  current_participants INT DEFAULT 1,
  trip_type ENUM('Adventure', 'Cultural', 'Leisure', 'Business', 'Medical', 'Other'),
  budget_estimate DECIMAL(10, 2),
  accessibility_notes TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  allow_invitations BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (organizer_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_organizer_id (organizer_id),
  INDEX idx_status (status),
  INDEX idx_start_date (start_date),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### trip_participants (New)
```sql
CREATE TABLE trip_participants (
  participant_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT NOT NULL,
  user_id INT NOT NULL,
  role ENUM('Organizer', 'Co-Organizer', 'Member') DEFAULT 'Member',
  invitation_status ENUM('Invited', 'Accepted', 'Rejected', 'Cancelled') DEFAULT 'Invited',
  invited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP NULL,
  is_live_tracking_enabled BOOLEAN DEFAULT TRUE,
  emergency_contact_visible BOOLEAN DEFAULT TRUE,
  trip_role_notes VARCHAR(500),
  UNIQUE KEY unique_trip_user (trip_id, user_id),
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_trip_id (trip_id),
  INDEX idx_user_id (user_id),
  INDEX idx_invitation_status (invitation_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### trip_itinerary (New)
```sql
CREATE TABLE trip_itinerary (
  itinerary_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT NOT NULL,
  day_number INT NOT NULL,
  date DATE NOT NULL,
  destination_id INT,
  location_name VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  start_time TIME,
  end_time TIME,
  description TEXT,
  activity_type VARCHAR(100),
  notes VARCHAR(500),
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_trip_id (trip_id),
  INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 3. Location & Tracking Tables

### live_locations (New)
```sql
CREATE TABLE live_locations (
  location_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT,
  user_id INT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy_meters DECIMAL(10, 2),
  speed_kmh DECIMAL(5, 2),
  bearing INT,
  address VARCHAR(500),
  city VARCHAR(100),
  country VARCHAR(100),
  is_safe BOOLEAN DEFAULT TRUE,
  risk_level ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Low',
  shared_with_group BOOLEAN DEFAULT TRUE,
  captured_at DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_trip_id (trip_id),
  INDEX idx_user_id (user_id),
  INDEX idx_captured_at (captured_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### location_history (New)
```sql
CREATE TABLE location_history (
  history_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  address VARCHAR(500),
  city VARCHAR(100),
  country VARCHAR(100),
  captured_at DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_captured_at (captured_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### geofences (New)
```sql
CREATE TABLE geofences (
  geofence_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  radius_meters INT NOT NULL,
  description VARCHAR(500),
  alert_on_entry BOOLEAN DEFAULT TRUE,
  alert_on_exit BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
  INDEX idx_trip_id (trip_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 4. Safety & Emergency Tables

### emergency_events (Expand from current)
```sql
CREATE TABLE emergency_events (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT,
  user_id INT NOT NULL,
  event_type ENUM('SOS', 'Incident', 'Separation', 'Other') DEFAULT 'SOS',
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  location_description VARCHAR(500),
  severity ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'High',
  description TEXT,
  status ENUM('Active', 'Responded', 'Resolved', 'Cancelled') DEFAULT 'Active',
  shared_with_contacts BOOLEAN DEFAULT TRUE,
  shared_with_authorities BOOLEAN DEFAULT FALSE,
  authorities_contacted_at TIMESTAMP NULL,
  emergency_contacts_notified INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_trip_id (trip_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### safety_incidents (New)
```sql
CREATE TABLE safety_incidents (
  incident_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT,
  location_latitude DECIMAL(10, 8),
  location_longitude DECIMAL(11, 8),
  location_name VARCHAR(255),
  incident_type VARCHAR(100),
  severity ENUM('Minor', 'Moderate', 'Severe', 'Critical'),
  description TEXT,
  reported_by_id INT,
  reported_at DATETIME NOT NULL,
  resolved BOOLEAN DEFAULT FALSE,
  resolved_at TIMESTAMP NULL,
  affected_users JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL,
  FOREIGN KEY (reported_by_id) REFERENCES users(user_id) ON DELETE SET NULL,
  INDEX idx_trip_id (trip_id),
  INDEX idx_location (location_latitude, location_longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### safety_risk_scores (New)
```sql
CREATE TABLE safety_risk_scores (
  score_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT NOT NULL,
  location_latitude DECIMAL(10, 8),
  location_longitude DECIMAL(11, 8),
  risk_score INT DEFAULT 0,
  weather_risk INT DEFAULT 0,
  incident_risk INT DEFAULT 0,
  isolation_risk INT DEFAULT 0,
  health_risk INT DEFAULT 0,
  overall_risk_level ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Low',
  risk_factors JSON,
  recommendations JSON,
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
  INDEX idx_trip_id (trip_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 5. Payment Tables

### bookings (New)
```sql
CREATE TABLE bookings (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT NOT NULL,
  user_id INT NOT NULL,
  booking_type VARCHAR(100),
  status ENUM('Pending', 'Confirmed', 'Cancelled', 'Completed') DEFAULT 'Pending',
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'PKR',
  payment_id INT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (payment_id) REFERENCES payments(payment_id),
  INDEX idx_trip_id (trip_id),
  INDEX idx_user_id (user_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### payments (New)
```sql
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  booking_id INT,
  trip_id INT,
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'PKR',
  payment_method ENUM('Card', 'Bank Transfer', 'Wallet', 'Mobile Money') NOT NULL,
  transaction_id VARCHAR(255),
  gateway_response JSON,
  status ENUM('Pending', 'Processing', 'Success', 'Failed', 'Refunded') DEFAULT 'Pending',
  paid_at TIMESTAMP NULL,
  failure_reason VARCHAR(500),
  refund_status ENUM('None', 'Partial', 'Full') DEFAULT 'None',
  refund_amount DECIMAL(10, 2),
  refund_reason VARCHAR(500),
  refunded_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE SET NULL,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### invoices (New)
```sql
CREATE TABLE invoices (
  invoice_id INT AUTO_INCREMENT PRIMARY KEY,
  payment_id INT NOT NULL,
  invoice_number VARCHAR(50) UNIQUE NOT NULL,
  user_id INT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL,
  issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  due_date DATE,
  paid_at TIMESTAMP NULL,
  file_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_invoice_number (invoice_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### trip_expenses (New)
```sql
CREATE TABLE trip_expenses (
  expense_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_id INT NOT NULL,
  created_by_id INT NOT NULL,
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'PKR',
  category VARCHAR(100),
  payment_date DATE NOT NULL,
  split_method ENUM('Equal', 'Itemized', 'Custom') DEFAULT 'Equal',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
  FOREIGN KEY (created_by_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_trip_id (trip_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### trip_expense_splits (New)
```sql
CREATE TABLE trip_expense_splits (
  split_id INT AUTO_INCREMENT PRIMARY KEY,
  expense_id INT NOT NULL,
  user_id INT NOT NULL,
  amount_owed DECIMAL(10, 2) NOT NULL,
  amount_paid DECIMAL(10, 2) DEFAULT 0,
  is_settled BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (expense_id) REFERENCES trip_expenses(expense_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE KEY unique_expense_user (expense_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 6. AI & Mental Health Tables

### ai_chat_history (Expand from current)
```sql
CREATE TABLE ai_chat_history (
  chat_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  trip_id INT,
  conversation_id VARCHAR(100),
  user_message TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  message_type ENUM('General', 'Travel', 'Safety', 'Weather', 'Route', 'Emergency', 'Other') DEFAULT 'General',
  context_data JSON,
  ai_confidence DECIMAL(3, 2),
  user_helpful_rating INT,
  tokens_used INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### mental_health_chats (New)
```sql
CREATE TABLE mental_health_chats (
  chat_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  trip_id INT,
  message TEXT NOT NULL,
  is_user_message BOOLEAN DEFAULT TRUE,
  mood_before VARCHAR(50),
  mood_after VARCHAR(50),
  wellness_score INT,
  topics JSON,
  response_type ENUM('Supportive', 'Informative', 'Directive', 'Reflective') DEFAULT 'Supportive',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### wellness_check_ins (New)
```sql
CREATE TABLE wellness_check_ins (
  check_in_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  trip_id INT,
  mood INT,
  stress_level INT,
  physical_health INT,
  notes TEXT,
  medications_taken BOOLEAN DEFAULT FALSE,
  sleep_quality INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 7. Notification Tables

### notifications (Keep & Expand from current)
```sql
CREATE TABLE notifications (
  notification_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  trip_id INT,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  notification_type ENUM('Safety', 'Weather', 'Trip', 'Payment', 'Wellness', 'Group', 'Emergency', 'System') DEFAULT 'System',
  priority ENUM('Low', 'Normal', 'High', 'Critical') DEFAULT 'Normal',
  action_type VARCHAR(100),
  action_data JSON,
  is_read BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  sent_via_push BOOLEAN DEFAULT FALSE,
  sent_via_email BOOLEAN DEFAULT FALSE,
  sent_via_sms BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_is_read (is_read),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### notification_preferences (New)
```sql
CREATE TABLE notification_preferences (
  preference_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNIQUE NOT NULL,
  push_notifications BOOLEAN DEFAULT TRUE,
  email_notifications BOOLEAN DEFAULT TRUE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  safety_alerts BOOLEAN DEFAULT TRUE,
  weather_alerts BOOLEAN DEFAULT TRUE,
  trip_updates BOOLEAN DEFAULT TRUE,
  payment_notifications BOOLEAN DEFAULT TRUE,
  wellness_reminders BOOLEAN DEFAULT TRUE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 8. Analytics & Logging Tables

### user_activity_logs (New)
```sql
CREATE TABLE user_activity_logs (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  activity_type VARCHAR(100) NOT NULL,
  action VARCHAR(100),
  resource_type VARCHAR(100),
  resource_id INT,
  ip_address VARCHAR(45),
  user_agent VARCHAR(500),
  status VARCHAR(50),
  details JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_activity_type (activity_type),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### admin_logs (New)
```sql
CREATE TABLE admin_logs (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  admin_user_id INT NOT NULL,
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(100),
  resource_id INT,
  target_user_id INT,
  changes JSON,
  reason VARCHAR(500),
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (admin_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (target_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
  INDEX idx_admin_user_id (admin_user_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### analytics_events (New)
```sql
CREATE TABLE analytics_events (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  trip_id INT,
  event_name VARCHAR(100) NOT NULL,
  event_category VARCHAR(100),
  event_value VARCHAR(255),
  event_data JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_event_name (event_name),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 9. Authentication & Security Tables

### email_verification_tokens (New)
```sql
CREATE TABLE email_verification_tokens (
  token_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  email VARCHAR(255) NOT NULL,
  token VARCHAR(255) UNIQUE NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_token (token),
  INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### password_reset_tokens (New)
```sql
CREATE TABLE password_reset_tokens (
  token_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  token VARCHAR(255) UNIQUE NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP NULL,
  reset_ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_token (token),
  INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### mfa_settings (New)
```sql
CREATE TABLE mfa_settings (
  mfa_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNIQUE NOT NULL,
  mfa_type ENUM('Email', 'SMS', 'Authenticator') NOT NULL,
  is_enabled BOOLEAN DEFAULT FALSE,
  secret_key VARCHAR(255),
  backup_codes JSON,
  verified_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### mfa_attempts (New)
```sql
CREATE TABLE mfa_attempts (
  attempt_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  mfa_type VARCHAR(50),
  is_successful BOOLEAN DEFAULT FALSE,
  attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(45),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_attempted_at (attempted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### session_tokens (New)
```sql
CREATE TABLE session_tokens (
  token_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  refresh_token VARCHAR(500) UNIQUE NOT NULL,
  device_name VARCHAR(100),
  device_type VARCHAR(50),
  is_revoked BOOLEAN DEFAULT FALSE,
  last_used_at TIMESTAMP NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_refresh_token (refresh_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 10. Content & Miscellaneous Tables

### ai_recommendations (Keep from current - already exists)
```sql
-- KEEP EXISTING TABLE
-- May need to expand with trip_context, confidence levels
```

### routes (Keep from current - already exists)
```sql
-- KEEP EXISTING TABLE
-- Extend with trip_id reference
```

### destinations (Keep from current - already exists)
```sql
-- KEEP EXISTING TABLE
```

### wishlists (Keep from current - already exists)
```sql
-- KEEP EXISTING TABLE
```

### reviews (Keep from current - already exists)
```sql
-- KEEP EXISTING TABLE
```

### weather_cache (Keep from current - already exists)
```sql
-- KEEP EXISTING TABLE
```

### user_preferences (Keep from current - existing)
```sql
-- KEEP EXISTING TABLE
-- Expand with additional preference fields
```

## Database Statistics

**Total Tables:** 38
- **Existing & Enhanced:** 10
- **New Critical Tables:** 28

**Estimated Database Size:** 100-200MB for 100K users over 6 months

**Key Relationships:**
- Users → Trips → Trip Participants → Live Locations
- Users → Emergency Events → Emergency Contacts
- Trips → Itinerary → Destinations
- Users → Payments → Bookings → Trips
- Users → Notifications
- Users → AI Chat History / Mental Health Chats

---

# COMPLETE API SPECIFICATION

## API Architecture

```
Version: 1.0
Base URL: https://api.safarsync.com/v1/
Authentication: Bearer JWT Token
Rate Limit: 100 requests/minute (authenticated), 10/minute (unauthenticated)
```

## Authentication Flow

### 1. Registration
**POST** `/auth/register`

Request:
```json
{
  "first_name": "Ahmed",
  "last_name": "Khan",
  "email": "ahmed@example.com",
  "phone_number": "+92300123456",
  "password": "SecurePass123!",
  "date_of_birth": "1990-01-15",
  "gender": "Male"
}
```

Response (201):
```json
{
  "success": true,
  "message": "Registration successful. Please verify your email.",
  "data": {
    "user_id": 123,
    "email": "ahmed@example.com",
    "email_verified": false,
    "verification_sent": true
  }
}
```

### 2. Email Verification
**POST** `/auth/verify-email`

Request:
```json
{
  "email": "ahmed@example.com",
  "token": "email_token_123"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

### 3. Login
**POST** `/auth/login`

Request:
```json
{
  "email": "ahmed@example.com",
  "password": "SecurePass123!"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "access_token": "jwt_token_abc...",
    "refresh_token": "refresh_token_xyz...",
    "expires_in": 3600,
    "user": {
      "user_id": 123,
      "email": "ahmed@example.com",
      "role": "Traveler"
    }
  }
}
```

### 4. MFA Setup
**POST** `/auth/mfa/setup`

Request:
```json
{
  "mfa_type": "Authenticator"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "qr_code_url": "https://...",
    "secret": "JBSWY3DPEBLW64TMMQ...",
    "backup_codes": ["code1", "code2", ...]
  }
}
```

### 5. Password Reset
**POST** `/auth/forgot-password`

Request:
```json
{
  "email": "ahmed@example.com"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Reset link sent to email"
}
```

**POST** `/auth/reset-password`

Request:
```json
{
  "token": "reset_token_123",
  "new_password": "NewPass123!"
}
```

## User Management APIs

### Get Profile
**GET** `/users/me`

Headers: `Authorization: Bearer {token}`

Response:
```json
{
  "success": true,
  "data": {
    "user_id": 123,
    "first_name": "Ahmed",
    "last_name": "Khan",
    "email": "ahmed@example.com",
    "phone_number": "+92300123456",
    "profile_picture_url": "https://...",
    "blood_group": "O+",
    "gender": "Male",
    "bio": "Travel enthusiast",
    "travel_style": "Adventure",
    "interests": ["Hiking", "Photography"],
    "role": "Traveler"
  }
}
```

### Update Profile
**PUT** `/users/me`

Request:
```json
{
  "bio": "Updated bio",
  "travel_style": "Luxury",
  "interests": ["Art", "Culture"]
}
```

### Add Emergency Contacts
**POST** `/users/me/emergency-contacts`

Request:
```json
{
  "contact_name": "Mother",
  "contact_phone": "+92333456789",
  "relationship": "Parent",
  "email": "mother@example.com",
  "is_primary": true
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "contact_id": 456,
    "contact_name": "Mother"
  }
}
```

### Get Emergency Contacts
**GET** `/users/me/emergency-contacts`

Response:
```json
{
  "success": true,
  "data": [
    {
      "contact_id": 456,
      "contact_name": "Mother",
      "contact_phone": "+92333456789",
      "relationship": "Parent",
      "is_primary": true
    }
  ]
}
```

## Trip Management APIs

### Create Trip
**POST** `/trips`

Request:
```json
{
  "trip_name": "Hunza Valley Adventure",
  "description": "5-day exploration of Hunza Valley",
  "start_date": "2026-07-15T08:00:00Z",
  "end_date": "2026-07-20T18:00:00Z",
  "destination_primary": "Hunza Valley",
  "latitude": 36.8506,
  "longitude": 74.3277,
  "trip_type": "Adventure",
  "max_participants": 8,
  "is_public": false,
  "budget_estimate": 50000
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "trip_id": 789,
    "trip_name": "Hunza Valley Adventure",
    "status": "Planned",
    "organizer_id": 123,
    "created_at": "2026-06-12T10:00:00Z"
  }
}
```

### Get Trip Details
**GET** `/trips/{trip_id}`

Response:
```json
{
  "success": true,
  "data": {
    "trip_id": 789,
    "trip_name": "Hunza Valley Adventure",
    "status": "Planned",
    "start_date": "2026-07-15T08:00:00Z",
    "end_date": "2026-07-20T18:00:00Z",
    "organizer": {
      "user_id": 123,
      "first_name": "Ahmed",
      "last_name": "Khan"
    },
    "participants": 3,
    "max_participants": 8,
    "members": [
      {
        "user_id": 123,
        "first_name": "Ahmed",
        "role": "Organizer",
        "status": "Accepted"
      }
    ],
    "itinerary": [
      {
        "day_number": 1,
        "date": "2026-07-15",
        "destination": "Gilgit",
        "activities": ["Travel", "Check-in"],
        "notes": "Arrive and settle in"
      }
    ]
  }
}
```

### Invite Participant
**POST** `/trips/{trip_id}/invite`

Request:
```json
{
  "email": "friend@example.com",
  "message": "Join our Hunza Valley trip!"
}
```

Response (200):
```json
{
  "success": true,
  "message": "Invitation sent"
}
```

### Accept Trip Invitation
**POST** `/trips/{trip_id}/accept-invitation`

Response (200):
```json
{
  "success": true,
  "message": "Invitation accepted"
}
```

### Add Itinerary
**POST** `/trips/{trip_id}/itinerary`

Request:
```json
{
  "day_number": 1,
  "date": "2026-07-15",
  "destination_id": 456,
  "location_name": "Gilgit",
  "latitude": 35.9271,
  "longitude": 74.3145,
  "start_time": "08:00",
  "end_time": "18:00",
  "activity_type": "Travel",
  "description": "Journey from Islamabad to Gilgit",
  "notes": "Leave early morning, bring snacks"
}
```

### Update Trip Status
**PUT** `/trips/{trip_id}/status`

Request:
```json
{
  "status": "Active"
}
```

### Get Trip Expenses
**GET** `/trips/{trip_id}/expenses`

Response:
```json
{
  "success": true,
  "data": {
    "total_expenses": 150000,
    "currency": "PKR",
    "expenses": [
      {
        "expense_id": 1,
        "description": "Hotel accommodation",
        "amount": 50000,
        "created_by": "Ahmed Khan",
        "category": "Accommodation",
        "splits": [
          {
            "user": "Ahmed Khan",
            "amount_owed": 25000
          },
          {
            "user": "Fatima Ali",
            "amount_owed": 25000
          }
        ]
      }
    ]
  }
}
```

## Location & Tracking APIs

### Update Live Location
**POST** `/location/update`

Request:
```json
{
  "trip_id": 789,
  "latitude": 36.8506,
  "longitude": 74.3277,
  "accuracy_meters": 5,
  "address": "Altit, Hunza Valley",
  "city": "Hunza",
  "country": "Pakistan",
  "speed_kmh": 60
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "location_id": 999,
    "latitude": 36.8506,
    "longitude": 74.3277
  }
}
```

### Get Group Locations (Real-time via Socket.io)
**WS** `/socket.io`

Emit:
```javascript
socket.emit('join:trip', { trip_id: 789 });
socket.on('location:updated', (data) => {
  console.log(data); // { user_id, latitude, longitude, timestamp }
});
```

### Get Location History
**GET** `/users/{user_id}/location-history?limit=50&days=7`

Response:
```json
{
  "success": true,
  "data": [
    {
      "history_id": 1,
      "latitude": 36.8506,
      "longitude": 74.3277,
      "address": "Altit, Hunza Valley",
      "captured_at": "2026-07-15T14:30:00Z"
    }
  ]
}
```

## Safety & Emergency APIs

### Trigger SOS
**POST** `/emergency/sos`

Request:
```json
{
  "latitude": 36.8506,
  "longitude": 74.3277,
  "location_description": "Near Altit Fort",
  "severity": "High"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "event_id": 2023,
    "status": "Active",
    "emergency_contacts_notified": 3,
    "authorities_contacted": true
  }
}
```

### Get Safety Risk Score
**GET** `/trips/{trip_id}/risk-score`

Response:
```json
{
  "success": true,
  "data": {
    "trip_id": 789,
    "overall_risk_score": 25,
    "risk_level": "Low",
    "risk_factors": {
      "weather": "Low",
      "incident_history": "Low",
      "isolation": "Medium",
      "health": "Low"
    },
    "recommendations": [
      "Carry sun protection",
      "Stay hydrated",
      "Keep emergency contacts updated"
    ]
  }
}
```

### Get Safety Alerts
**GET** `/trips/{trip_id}/alerts`

Response:
```json
{
  "success": true,
  "data": {
    "alerts": [
      {
        "alert_id": 1,
        "alert_type": "Weather",
        "severity": "Medium",
        "message": "Heavy rain expected in 2 hours",
        "recommendation": "Seek shelter and delay travel",
        "created_at": "2026-07-15T14:30:00Z"
      }
    ]
  }
}
```

## Payment APIs

### Create Booking
**POST** `/bookings`

Request:
```json
{
  "trip_id": 789,
  "booking_type": "Trip Participation",
  "amount": 15000
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "booking_id": 555,
    "trip_id": 789,
    "amount": 15000,
    "status": "Pending"
  }
}
```

### Process Payment
**POST** `/payments/process`

Request:
```json
{
  "booking_id": 555,
  "payment_method": "Card",
  "card_token": "stripe_token_xyz"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "payment_id": 1023,
    "status": "Success",
    "transaction_id": "trans_abc123",
    "amount": 15000,
    "invoice_url": "https://..."
  }
}
```

### Get Payment History
**GET** `/users/me/payments`

Response:
```json
{
  "success": true,
  "data": {
    "total_count": 5,
    "payments": [
      {
        "payment_id": 1023,
        "trip_name": "Hunza Valley Adventure",
        "amount": 15000,
        "status": "Success",
        "paid_at": "2026-06-15T10:00:00Z",
        "invoice_url": "https://..."
      }
    ]
  }
}
```

## AI Assistant APIs

### Send Message to AI
**POST** `/ai/chat`

Request:
```json
{
  "message": "What should I pack for a mountain trip?",
  "context": {
    "trip_id": 789,
    "destination": "Hunza Valley",
    "weather": "Mild, occasional rain",
    "duration_days": 5
  }
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "chat_id": 3001,
    "user_message": "What should I pack for a mountain trip?",
    "ai_response": "For a Hunza Valley trip, I recommend: waterproof jacket, sturdy hiking boots, sun protection, layers for temperature changes...",
    "message_type": "Travel",
    "confidence": 0.95
  }
}
```

### Get Travel Recommendations
**GET** `/ai/recommendations?trip_id=789`

Response:
```json
{
  "success": true,
  "data": {
    "recommendations": [
      {
        "type": "Safety",
        "message": "Keep hydrated in high altitude",
        "confidence": 0.98
      },
      {
        "type": "Route",
        "message": "Best route avoids traffic at 8 AM",
        "confidence": 0.92
      }
    ]
  }
}
```

## Mental Health APIs

### Send Wellness Chat Message
**POST** `/mental-health/chat`

Request:
```json
{
  "message": "I'm feeling anxious about the trip",
  "trip_id": 789
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "chat_id": 4001,
    "response": "It's normal to feel anxious before a trip. Let's talk about what's worrying you most...",
    "mood_suggestion": "Take 5 deep breaths"
  }
}
```

### Daily Wellness Check-in
**POST** `/mental-health/check-in`

Request:
```json
{
  "mood": 7,
  "stress_level": 4,
  "sleep_quality": 8,
  "notes": "Excited for the trip"
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "check_in_id": 5001,
    "wellness_suggestion": "Your mood is positive! Maintain energy levels with regular breaks"
  }
}
```

## Weather APIs

### Get Weather for Trip
**GET** `/weather/trip/{trip_id}`

Response:
```json
{
  "success": true,
  "data": {
    "current": {
      "temperature": 22,
      "condition": "Partly Cloudy",
      "humidity": 65,
      "wind_speed": 12
    },
    "forecast": [
      {
        "date": "2026-07-15",
        "high": 28,
        "low": 18,
        "condition": "Sunny",
        "precipitation": 0
      }
    ],
    "alerts": [
      "Heavy rain possible on Day 3"
    ]
  }
}
```

## Notification APIs

### Get Notifications
**GET** `/notifications?limit=20&unread_only=false`

Response:
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "notification_id": 6001,
        "title": "Weather Alert",
        "message": "Heavy rain expected in your destination",
        "notification_type": "Weather",
        "priority": "High",
        "is_read": false,
        "created_at": "2026-07-15T14:30:00Z"
      }
    ]
  }
}
```

### Mark Notification as Read
**PUT** `/notifications/{notification_id}/read`

## Admin APIs

### Get Dashboard Stats
**GET** `/admin/dashboard/stats`

Authorization: `Admin` role required

Response:
```json
{
  "success": true,
  "data": {
    "total_users": 5234,
    "active_users_today": 1203,
    "active_trips": 89,
    "total_trips": 2341,
    "total_bookings": 5234,
    "revenue": {
      "total": 2500000,
      "currency": "PKR",
      "period": "last_30_days"
    }
  }
}
```

### List Users (Admin)
**GET** `/admin/users?page=1&limit=20`

Authorization: `Admin` role required

Response:
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "user_id": 123,
        "email": "user@example.com",
        "role": "Traveler",
        "status": "Active",
        "created_at": "2026-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5234
    }
  }
}
```

### Ban User (Admin)
**POST** `/admin/users/{user_id}/ban`

Request:
```json
{
  "reason": "Inappropriate behavior"
}
```

### Get Safety Incidents (Admin)
**GET** `/admin/incidents?days=30`

Response:
```json
{
  "success": true,
  "data": {
    "incidents": [
      {
        "incident_id": 7001,
        "user_id": 456,
        "location": "Hunza Valley",
        "incident_type": "SOS Activated",
        "severity": "High",
        "created_at": "2026-07-15T14:30:00Z",
        "resolved": true
      }
    ]
  }
}
```

## Complete Endpoint Summary

**Total API Endpoints:** 50+

**Authentication:** 8 endpoints
**User Management:** 6 endpoints  
**Trip Management:** 12 endpoints
**Location & Tracking:** 4 endpoints
**Safety & Emergency:** 5 endpoints
**Payments:** 4 endpoints
**AI Assistant:** 4 endpoints
**Mental Health:** 3 endpoints
**Weather:** 2 endpoints
**Notifications:** 3 endpoints
**Admin:** 8+ endpoints
**Miscellaneous:** 5+ endpoints

---

# FRONTEND SCREEN ARCHITECTURE

## Complete Screen Hierarchy

```
SAFARSYNC FLUTTER APP STRUCTURE:

├── Auth Flows
│   ├── Splash Screen
│   ├── Login Screen
│   ├── Signup Screen
│   ├── Email Verification
│   ├── MFA Setup
│   ├── MFA Verification
│   ├── Forgot Password
│   └── Reset Password
│
├── Home Section
│   ├── Dashboard Home
│   ├── Quick Access Cards
│   ├── Smart Alerts Widget
│   ├── AI Recommendations Widget
│   ├── Weather Widget
│   └── Emergency SOS Button
│
├── Trip Management
│   ├── My Trips List
│   ├── Create Trip
│   ├── Trip Details
│   ├── Trip Itinerary
│   ├── Trip Members
│   ├── Trip Expenses
│   ├── Trip Status
│   └── Past Trips
│
├── Travel Planning
│   ├── Explore Destinations
│   ├── Destination Details
│   ├── Smart Route Planner
│   ├── Route Optimization
│   ├── Hotel Finder
│   ├── Food Spots Finder
│   ├── Wishlist
│   └── Reviews & Ratings
│
├── Location & Tracking
│   ├── Live Map
│   ├── Group Members Map
│   ├── Location History
│   ├── Safe Arrival Confirmation
│   └── Geofence Alerts
│
├── Safety & Emergency
│   ├── Emergency Contacts
│   ├── SOS Button
│   ├── Safety Score Display
│   ├── Safety Incidents
│   ├── Risk Alerts
│   └── Emergency Call Screen
│
├── Communication
│   ├── Trip Chat
│   ├── Group Announcements
│   ├── Notifications Center
│   ├── Notification Settings
│   └── Message History
│
├── Wellness
│   ├── Mental Health Chat
│   ├── Daily Check-in
│   ├── Mood Tracker
│   ├── Wellness Resources
│   └── Meditation/Breathing Exercises
│
├── Payments
│   ├── Booking Screen
│   ├── Payment Gateway
│   ├── Payment History
│   ├── Invoice/Receipt
│   ├── Expense Splitting
│   └── Settlement Requests
│
├── User Profile
│   ├── Profile Overview
│   ├── Edit Profile
│   ├── Security Settings
│   ├── Notification Preferences
│   ├── Accessibility Settings
│   ├── Privacy Settings
│   └── Account Management
│
└── Settings
    ├── General Settings
    ├── Theme (Dark/Light)
    ├── Language
    ├── About App
    ├── Help & Support
    ├── Feedback
    └── Logout
```

## Detailed Screen Specifications

### 1. Authentication Screens

#### Splash Screen
**Purpose:** App initialization, theme loading, session check

**Components:**
- SafarSync Logo (animated)
- Loading indicator
- Auto-navigate to login/home based on auth state

**User Flow:**
```
Splash → Check Auth Token → 
  If Valid → Dashboard Home
  If Expired → Login
  If None → Login
```

#### Login Screen
**Purpose:** User authentication

**Components:**
- Email input field
- Password input field
- Remember me checkbox
- Forgot password link
- Sign up link
- Login button
- Social login options (Google, Apple)
- Error message display

**Validations:**
- Email format validation
- Password requirement validation
- Rate limiting (5 attempts, 15 min cooldown)

**User Flow:**
```
Login → 
  MFA Enabled? 
    → MFA Verification Screen
  MFA Disabled?
    → Dashboard
```

#### MFA Setup Screen
**Purpose:** Setup multi-factor authentication

**Components:**
- MFA type selection (Email, SMS, Authenticator)
- QR code (for Authenticator)
- Secret key display
- Backup codes display
- Backup codes save option
- Verify button

**User Flow:**
```
MFA Setup → Select Type → Configure → Save Backup Codes → Test Verification → Dashboard
```

### 2. Home Section Screens

#### Dashboard Home
**Purpose:** Central hub, quick access to features

**Components:**
- User greeting ("Welcome, Ahmed!")
- Quick action cards (New Trip, View Trips, Explore)
- Smart Alerts section
- Weather widget
- Recommendations carousel
- Emergency SOS button (floating)
- Upcoming trips preview
- Group notifications badge

**Layout:**
```
┌─────────────────────────┐
│  Welcome, Ahmed!        │ <- Greeting
├─────────────────────────┤
│ ┌─ Quick Actions ─────┐ │
│ │ New Trip │ My Trips │ │
│ └─────────────────────┘ │
├─────────────────────────┤
│ ⚠️ Smart Alerts        │ <- 1 alert
├─────────────────────────┤
│ Weather: 22°C, Sunny   │
├─────────────────────────┤
│ Recommended for you:   │
│ [Destination Card]     │
├─────────────────────────┤
│ Upcoming Trips:        │
│ [Trip Card]            │
├─────────────────────────┤
│ [  SOS  ] Emergency     │ <- Floating button
└─────────────────────────┘
```

### 3. Trip Management Screens

#### My Trips List
**Purpose:** View all user trips

**Components:**
- Tab navigation (Planned, Active, Completed, Past)
- Trip cards with:
  - Trip name
  - Destination
  - Dates
  - Member count
  - Status badge
  - Action menu (View, Edit, Share, Delete)
- Floating action button (New Trip)
- Search & filter

**Features:**
- Sort by date/status
- Filter by trip type
- Search by trip name

#### Create Trip Screen
**Purpose:** Create new group trip

**Components:**
- Trip name input
- Description input
- Start date/time picker
- End date/time picker
- Destination selector (map/search)
- Trip type selector
- Max participants input
- Accessibility notes
- Public/Private toggle
- Create button

**Validations:**
- Trip name required
- End date > start date
- Dates not in past
- Max participants > 1

**User Flow:**
```
Create Trip → Fill Details → Select Location → Configure → Create → Add Members → Start Trip
```

#### Trip Details Screen
**Purpose:** View/manage trip

**Tabs:**
1. **Overview**
   - Trip info
   - Organizer details
   - Dates and location
   - Member count
   - Trip status

2. **Members**
   - List of participants
   - Role indicators
   - Action buttons (Remove, Message)
   - Invite new member

3. **Itinerary**
   - Day-by-day breakdown
   - Activities
   - Locations
   - Times
   - Add/edit days

4. **Expenses**
   - Total expenses
   - Expense list
   - Splits breakdown
   - Settlement status
   - Add expense button

5. **Chat**
   - Trip group messages
   - Announcements
   - File sharing

6. **Map**
   - Live locations of members
   - Destinations
   - Routes

### 4. Location & Tracking Screens

#### Live Map Screen
**Purpose:** Real-time tracking of trip members

**Components:**
- Full-screen map
- User location markers
- Member avatars
- Location accuracy circle
- Route overlay
- Geofence indicators
- Zoom controls
- Center on me button
- Member list panel

**Real-Time Updates:**
- Socket.io live location updates
- Zoom to fit all members
- Highlight selected member
- Show location history trail

**User Flow:**
```
Open Map → View Live Locations → Select Member → See Member Details → Route Overlay → Alerts
```

#### Safe Arrival Confirmation
**Purpose:** Notify others of safe arrival

**Components:**
- Current location display
- Confirmation button
- Notification recipients list
- Message input
- Share button

**User Flow:**
```
Arrive → Tap Safe Arrival → Confirm → Notify Members → Close Alert
```

### 5. Safety & Emergency Screens

#### Emergency SOS Screen
**Purpose:** Emergency response

**Components:**
- Large SOS button (red, prominent)
- Current location display
- Emergency contacts quick dial
- SOS status
- Countdown timer
- Cancel button

**Features:**
- One-tap activation
- Simultaneous notification to:
  - Emergency contacts
  - Authorities
  - Trip members
- Real-time location sharing
- Automatic call to primary contact option

**User Flow:**
```
Press SOS → Confirm → Emergency Activated → Location Shared → Contact Notified → Respond
```

#### Safety Alerts Screen
**Purpose:** View safety alerts

**Components:**
- Alert list by severity
- Risk score indicator
- Recommendations list
- Alert history

**Alert Types:**
- Weather alerts
- Incident reports
- Geofence breaches
- Member disconnection
- Environmental hazards

### 6. AI Assistant Screen

#### SafarAI Chat
**Purpose:** AI travel assistance

**Components:**
- Chat history view
- Message input field
- Suggestion chips
- AI response with context
- Copy/share response
- Rating (helpful/not helpful)

**Features:**
- Context-aware responses
- Travel tips
- Safety advice
- Weather insights
- Route suggestions
- Destination recommendations
- Emergency guidance

**Example Conversation:**
```
User: "What should I pack?"
AI: "Based on your Hunza Valley trip with high altitude, I recommend: 
    - Waterproof jacket
    - Layers for temperature changes
    - Sun protection (SPF 50+)
    - Hydration supplements
    [Helpful?] [Not Helpful]"
```

### 7. Mental Health Screen

#### Wellness Chat
**Purpose:** Mental health support

**Components:**
- Chat interface
- Mood selector (emoji-based)
- Wellness suggestions
- Resources list
- Crisis hotline button
- Chat history

**Features:**
- Supportive responses
- Mood tracking
- Daily check-in reminders
- Meditation/breathing exercises
- Coping strategies
- Resource recommendations

**User Flow:**
```
Open Wellness → Select Mood → Chat → Receive Suggestions → Access Resources → Check-in Later
```

#### Daily Check-in
**Purpose:** Track wellness during trip

**Components:**
- Mood slider (1-10)
- Stress level slider
- Sleep quality input
- Physical health assessment
- Notes input
- Submit button

**Features:**
- Quick 1-minute assessment
- Trend visualization
- Personalized suggestions
- Health warnings if needed

### 8. Payment Screen

#### Payment Processing
**Purpose:** Secure payment for trip participation

**Components:**
- Order summary
- Amount display
- Payment method selector (Card, Bank, Wallet)
- Card input (if card selected)
- Security indicators
- Pay button
- Cancel button

**Features:**
- Multiple payment methods
- Secure payment gateway
- Receipt generation
- Invoice download
- Payment history

**User Flow:**
```
Booking → View Amount → Select Payment Method → Enter Details → Process Payment → Receipt
```

### 9. Profile Screen

#### User Profile
**Purpose:** View/edit user information

**Sections:**
1. **Profile Header**
   - Profile picture
   - Name
   - Member since date
   - Travel statistics

2. **Personal Info**
   - Name
   - Email
   - Phone
   - Gender
   - Date of birth

3. **Travel Info**
   - Travel style
   - Budget range
   - Interests
   - Accessibility needs

4. **Safety Info**
   - Blood group
   - Medical conditions
   - Allergies
   - Emergency contacts

5. **Edit Button**
   - Opens edit mode
   - Save/Cancel buttons

### 10. Settings Screen

**Options:**
- Theme (Dark/Light/Auto)
- Language
- Notifications
- Privacy
- Account security
- Connected apps
- Help
- About
- Logout

---

# ADMIN DASHBOARD ARCHITECTURE

## Admin Panel Overview

```
ADMIN SAFARSYNC DASHBOARD

├── Dashboard
│   ├── Stats Overview
│   ├── Charts & Graphs
│   └── Quick Actions
│
├── User Management
│   ├── User List
│   ├── User Details
│   ├── Ban/Unban Users
│   ├── Verify Accounts
│   └── User Analytics
│
├── Trip Management
│   ├── Active Trips
│   ├── Trip Monitoring
│   ├── Trip Details
│   ├── Flag/Investigate Trips
│   └── Trip Analytics
│
├── Safety & Incidents
│   ├── Incident Reports
│   ├── SOS Events
│   ├── Risk Assessments
│   ├── Area Safety Scores
│   └── Authorities Coordination
│
├── Payments & Finance
│   ├── Transaction History
│   ├── Revenue Reports
│   ├── Refund Requests
│   ├── Payment Analytics
│   └── Financial Reports
│
├── AI & Content
│   ├── AI Usage Stats
│   ├── Chat Monitoring
│   ├── Destination Management
│   ├── Content Moderation
│   └── Recommendation Quality
│
├── Mental Health
│   ├── Wellness Usage
│   ├── Crisis Incidents
│   ├── Resource Effectiveness
│   └── User Trends
│
├── Analytics & Reporting
│   ├── User Analytics
│   ├── Trip Analytics
│   ├── Financial Analytics
│   ├── Safety Analytics
│   ├── Custom Reports
│   └── Export Data
│
├── Configuration
│   ├── System Settings
│   ├── Payment Gateway
│   ├── Notification Settings
│   ├── Alert Thresholds
│   ├── Rate Limiting
│   └── Maintenance Mode
│
└── Audit & Compliance
    ├── Admin Logs
    ├── Access History
    ├── Data Logs
    ├── Compliance Reports
    └── Backups
```

## Key Admin Screens

### 1. Dashboard Overview
**Components:**
- Total users card (with trend)
- Active trips card
- Revenue card
- Safety incidents card
- AI usage card
- Quick actions
- Charts:
  - User growth (30-day)
  - Trip frequency
  - Revenue trend
  - Incident distribution

### 2. User Management
**Features:**
- User list with filters
- Search by email/name
- Columns: ID, Name, Email, Role, Status, Created Date, Actions
- Bulk actions (Ban, Verify, Delete)
- User detail view:
  - Profile info
  - Activity history
  - Trips organized
  - Safety record
  - Payment history
  - Ban user button with reason input

### 3. Safety Monitoring
**Features:**
- Incident dashboard
- SOS events log
- Risk score by location
- Affected users
- Response actions
- Historical trends
- Alert threshold configuration

### 4. Financial Dashboard
**Features:**
- Revenue overview
- Transaction history
- Refund requests management
- Financial reports
- Export capabilities
- Tax compliance data

---

# AI & SAFETY ENGINE DESIGN

## 1. Travel Risk Score Algorithm

### Risk Score Calculation (0-100)

```
Risk Score = (Weather Risk × 0.25) + (Incident Risk × 0.25) + 
             (Isolation Risk × 0.20) + (Health Risk × 0.15) + 
             (Time Risk × 0.15)

Risk Level Classification:
  0-25   = Low Risk (Green)
  26-50  = Medium Risk (Yellow)
  51-75  = High Risk (Orange)
  76-100 = Critical Risk (Red)
```

### Risk Components

#### Weather Risk (0-100)
```
Factors:
- Temperature extremes (too hot/cold)
- Precipitation (rain/snow)
- Wind speeds
- Weather alerts
- Climate hazards (avalanche, flash flood)
- Seasonal variations

Example:
- Clear weather: 5
- Light rain: 25
- Heavy rain/storm: 70
- Extreme weather alert: 95
```

#### Incident Risk (0-100)
```
Factors:
- Historical incidents at location
- Crime statistics
- Traffic accident rates
- Environmental hazards
- Recent incidents (last 30 days)
- Area safety reports

Example:
- Safe area: 10
- Occasional incidents: 35
- Recent incident (7 days): 60
- Active danger: 85
```

#### Isolation Risk (0-100)
```
Factors:
- Distance from emergency services
- Mobile network coverage
- Road accessibility
- Altitude/remoteness
- Group size vs. hazard level
- Communication capability

Example:
- Urban area: 5
- Rural area: 30
- Remote location: 60
- Very remote: 85
```

#### Health Risk (0-100)
```
Factors:
- Altitude
- Temperature
- Physical demands
- Medical requirements
- Healthcare availability
- User health profile (allergies, conditions)

Example:
- Low altitude, sea level: 10
- Medium altitude (1000-2000m): 30
- High altitude (2500-3500m): 60
- Very high altitude (>4000m): 85
```

#### Time Risk (0-100)
```
Factors:
- Time of day
- Darkness levels
- Travel time remaining
- Night travel necessity
- Fatigue accumulation

Example:
- Daytime travel: 10
- Evening travel: 30
- Night travel: 60
- Multiple nights: 75
```

### Risk Score Examples

```
Scenario 1: Hunza Valley Day Trip
- Weather: Clear (5)
- Incident: Safe area (15)
- Isolation: Rural (25)
- Health: Altitude 2500m (35)
- Time: Daytime (10)
Risk Score: 18/100 = LOW RISK ✅

Scenario 2: Remote Mountain Overnight
- Weather: Storm warning (70)
- Incident: Accident zone (45)
- Isolation: Very remote (75)
- Health: High altitude (65)
- Time: Night travel (60)
Risk Score: 63/100 = HIGH RISK ⚠️

Scenario 3: Solo Night Urban Travel
- Weather: Clear (10)
- Incident: Moderate crime (40)
- Isolation: City (15)
- Health: Normal (20)
- Time: Night solo (75)
Risk Score: 32/100 = MEDIUM RISK ⚠️
```

## 2. Smart Alert System

### Alert Types & Triggers

#### Safety Alerts
```
Alert: "Group member disconnected"
Trigger: No location update for 30 minutes
Severity: High
Action: Notify organizer + group

Alert: "Route deviation detected"
Trigger: User 2km+ off planned route
Severity: Medium
Action: Notify user + ask confirmation

Alert: "Geofence breach"
Trigger: Member exits defined safety zone
Severity: High
Action: Alert organizer + send location update

Alert: "Emergency contact unreachable"
Trigger: SOS sent, no response in 5 min
Severity: Critical
Action: Try alternate contact + alert authorities
```

#### Weather Alerts
```
Alert: "Heavy rain in 2 hours"
Trigger: Weather API + location
Severity: Medium
Recommendation: "Seek shelter or delay travel"

Alert: "Flash flood risk"
Trigger: Rainfall >50mm + low-lying area
Severity: Critical
Recommendation: "Evacuate to higher ground immediately"

Alert: "Extreme heat warning"
Trigger: Temperature >45°C + trip active
Severity: High
Recommendation: "Stay hydrated, take breaks, avoid sun"

Alert: "Avalanche risk"
Trigger: Heavy snow + mountain area
Severity: Critical
Recommendation: "Do not venture into avalanche zones"
```

#### Health Alerts
```
Alert: "High altitude warning"
Trigger: Altitude >3500m + new member
Severity: Medium
Recommendation: "Acclimatize gradually, watch for altitude sickness"

Alert: "Fatigue warning"
Trigger: >12 hours continuous travel
Severity: High
Recommendation: "Take 2-hour rest break"

Alert: "Dehydration risk"
Trigger: High temp + low water intake + trip duration
Severity: Medium
Recommendation: "Drink 500ml water every hour"
```

## 3. AI Recommendations Engine

### Context-Aware Recommendations

```
RECOMMENDATION FRAMEWORK:

User Context:
- User profile (preferences, budget, interests)
- Travel history
- Current trip details
- Location
- Time
- Group composition
- Weather conditions

AI generates:
- Travel safety recommendations
- Route suggestions
- Activity recommendations
- Packing recommendations
- Budget optimization
- Accessibility accommodations
- Cultural sensitivity tips

Example:
User: "What should I pack for Hunza Valley?"
Context:
  - Destination: Hunza Valley (2500m altitude)
  - Duration: 5 days
  - Season: July (summer)
  - Weather: Mild, occasional rain
  - User: Solo female traveler

AI Response:
"For your Hunza Valley trip, I recommend:

ESSENTIAL:
- Waterproof jacket (rain expected)
- Sturdy hiking boots
- SPF 50+ sunscreen
- Hat & sunglasses
- Hydration (2L+ capacity)

CLOTHING:
- Moisture-wicking layers
- Comfortable trekking pants
- Thermal wear (nights cool)

HEALTH/SAFETY:
- First aid kit
- Altitude sickness medication (consult doctor)
- Personal medications
- Menstrual products if needed

TECH:
- Portable charger
- Offline maps
- Emergency whistle

BUDGET OPTIMIZATION:
- Visit local markets for fresh food (40% cheaper)
- Stay in guesthouses ($15-30/night)
- Hire local guide (40% cheaper than agencies)

CULTURAL TIPS:
- Learn basic Urdu greetings
- Dress modestly in villages
- Ask permission before photography

SAFETY TIPS:
- Share itinerary with family
- Register with embassy (if international)
- Keep emergency contacts updated
- Report location daily to family"

Confidence: 0.95
Time to Generate: 2.3 seconds
User Rating: 👍
```

## 4. Mental Health Support Algorithm

### Wellness Scoring

```
WELLNESS SCORE = (Mood × 0.3) + (Stress × 0.25) + (Sleep × 0.2) + 
                 (Physical × 0.15) + (Social × 0.1)

Score Range:
0-2 = Critical (Red)
3-4 = Poor (Orange)
5-6 = Average (Yellow)
7-8 = Good (Light Green)
9-10 = Excellent (Green)
```

### Mental Health Responses

```
Scenario: User reports high stress (8/10)

AI Response:
"I notice you're feeling quite stressed. That's understandable with trip preparations. 
Let's work through this together.

IMMEDIATE COPING:
- Try 5-4-3-2-1 grounding: Name 5 things you see, 4 you hear, 3 you feel, 2 you smell, 1 you taste
- Do 5 minutes of deep breathing
- Take a 10-minute walk

UNDERLYING CONCERNS:
Let's talk about what's causing the stress. Is it:
- Travel logistics?
- Group dynamics?
- Personal worries?
- Physical health concerns?
- Financial stress?

RESOURCES:
- Meditation app: [Recommendation]
- Crisis hotline: [Number]
- Counselor chat: [Link]

You're doing great. Stress is normal, but you're not alone."

Follow-up: 4-hour reminder to check in
```

---

# SECURITY IMPLEMENTATION PLAN

## 1. Authentication & Authorization

### JWT Strategy
```
ACCESS TOKEN:
- Lifetime: 1 hour
- Payload: user_id, email, role, permissions
- Signature: HS256 with JWT_SECRET

REFRESH TOKEN:
- Lifetime: 30 days
- Stored in: Secure HTTP-only cookie
- Revocable in: session_tokens table
- Renewed: Every 7 days

MFA_TOKEN:
- Lifetime: 5 minutes
- Used for: MFA verification
- Invalidated: After successful MFA
```

### MFA Implementation
```
TOTP (Time-based One-Time Password):
- Google Authenticator compatible
- 30-second window
- 6-digit codes
- Backup codes (10) stored encrypted

EMAIL OTP:
- 6-digit codes
- 10-minute expiry
- Rate limited (5 attempts)

SMS OTP:
- 6-digit codes
- 10-minute expiry
- Rate limited (5 attempts)
```

### Role-Based Access Control
```
ROLES:
1. TRAVELER
   - Create own trips
   - Join group trips
   - View own data
   - Use AI/wellness features

2. ORGANIZER
   - Create & manage group trips
   - Manage participants
   - View trip data
   - Manage expenses

3. ADMIN
   - Full system access
   - User management
   - Safety monitoring
   - Financial reports
   - System configuration

PERMISSION MATRIX:
┌────────────────┬──────────┬──────────┬───────┐
│ Resource       │ Traveler │ Organizer│ Admin │
├────────────────┼──────────┼──────────┼───────┤
│ Own Profile    │ RW       │ RW       │ R     │
│ Other Profiles │ R        │ R        │ RW    │
│ Own Trips      │ RW       │ CRUD     │ R     │
│ All Trips      │ -        │ -        │ RW    │
│ Payments       │ RW*      │ RW*      │ RW    │
│ Admin Panel    │ -        │ -        │ CRUD  │
│ User Reports   │ -        │ -        │ CRUD  │
│ Safety Data    │ Own      │ Trip     │ All   │
└────────────────┴──────────┴──────────┴───────┘

* Own trips only
```

## 2. Data Protection

### Encryption Strategy
```
AT REST:
- Medical fields: AES-256
- Emergency contacts: AES-256
- Payment data: PCI-DSS compliant
- Passwords: bcrypt (cost: 12)

IN TRANSIT:
- All APIs: TLS 1.3
- All cookies: Secure + HttpOnly
- CORS: Whitelisted origins only

SENSITIVE FIELDS TO ENCRYPT:
- blood_group
- medical_conditions
- allergies
- emergency_contact_phone
- payment_card_tokens
- SSN/ID numbers
```

### Field-Level Encryption
```
const encryptField = (value, key) => {
  const cipher = crypto.createCipher('aes-256-cbc', key);
  let encrypted = cipher.update(value, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
};

const decryptField = (encrypted, key) => {
  const decipher = crypto.createDecipher('aes-256-cbc', key);
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
};

// Usage in queries
await db.query(
  'UPDATE users SET blood_group = ? WHERE user_id = ?',
  [encryptField(bloodGroup, ENCRYPTION_KEY), userId]
);
```

## 3. Input Validation & Sanitization

### Validation Middleware
```javascript
const validateInput = (req, res, next) => {
  // Sanitize all inputs
  req.body = sanitizeObject(req.body);
  
  // Validate against schema
  const schema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(8).required(),
    phone_number: Joi.string().regex(/^\+92\d{10}$/).optional()
  });
  
  const { error, value } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  
  req.body = value;
  next();
};

const sanitizeObject = (obj) => {
  const sanitized = {};
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      sanitized[key] = DOMPurify.sanitize(value);
    } else {
      sanitized[key] = value;
    }
  }
  return sanitized;
};
```

## 4. Rate Limiting

### Rate Limit Rules
```
UNAUTHENTICATED:
- Login attempts: 5 per 15 minutes
- Registration: 3 per hour
- Password reset: 3 per hour
- API calls: 10 per minute

AUTHENTICATED:
- API calls: 100 per minute
- Payment operations: 5 per hour
- Location updates: 1 per 10 seconds
- SOS activation: 1 per 5 minutes

ADMIN:
- Unrestricted but logged
```

### Implementation
```javascript
const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts, try again in 15 minutes',
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.user && req.user.role === 'Admin'
});

const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000,
  max: (req) => req.user ? 100 : 10,
  keyGenerator: (req) => req.user?.user_id || req.ip
});

app.post('/auth/login', loginLimiter, loginUser);
app.use('/api/', apiLimiter);
```

## 5. CORS Configuration

```javascript
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS.split(','),
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 3600
};

app.use(cors(corsOptions));

// CSRF Protection
const csrf = require('csurf');
const csrfProtection = csrf({ cookie: false });
app.post('/*', csrfProtection);
```

## 6. API Security Headers

```javascript
const helmet = require('helmet');

app.use(helmet());
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],
    imgSrc: ["'self'", "data:", "https:"],
    connectSrc: ["'self'", "https://api.safarsync.com"]
  }
}));

// Additional headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
});
```

## 7. Audit Logging

### Log Critical Events
```
EVENTS TO LOG:
- Login attempts (success/failure)
- MFA setup/change
- Password change
- Permission changes
- Data exports
- Admin actions
- Payment operations
- SOS activation
- Emergency contact changes

LOG FORMAT:
{
  "timestamp": "2026-07-15T14:30:00Z",
  "user_id": 123,
  "action": "login_success",
  "resource": "auth",
  "ip_address": "192.168.1.1",
  "user_agent": "Mozilla/5.0...",
  "details": { "mfa_used": true },
  "status": "success"
}

STORAGE:
- Database: admin_logs + user_activity_logs
- Archive: Daily export to S3 (encrypted)
- Retention: 2 years minimum
```

## 8. Security Checklist

- ✅ All passwords hashed with bcrypt (cost 12)
- ✅ All APIs use HTTPS/TLS 1.3
- ✅ All PII encrypted at rest
- ✅ CORS restricted to whitelisted origins
- ✅ Rate limiting on all sensitive endpoints
- ✅ Input validation on all endpoints
- ✅ CSRF protection on all state-changing operations
- ✅ SQL injection prevention via parameterized queries
- ✅ XSS prevention via input sanitization
- ✅ Admin operations logged and audited
- ✅ Refresh tokens revocable
- ✅ Session timeout after 1 hour of inactivity
- ✅ MFA required for admin operations
- ✅ Emergency contact changes require confirmation
- ✅ Payment data PCI-DSS compliant

---

# DEVELOPMENT ROADMAP

## Project Timeline: 90 Days (12 Weeks)

### Phase 1: Foundation & Security (Weeks 1-3)

#### Week 1: Setup & Database Migration
**Deliverables:**
- Complete database schema migration
- Create all 38 tables
- Setup indexes and foreign keys
- Data backup strategy
- Migration scripts

**Tasks:**
```
Database:
☐ Create users table expansion
☐ Create roles & permissions tables
☐ Create authentication tables (tokens, MFA, sessions)
☐ Create trip management tables
☐ Create location tracking tables
☐ Create payment tables
☐ Create safety tables
☐ Create analytics tables
☐ Run migrations and validate
☐ Setup database backups (daily)

Backend:
☐ Update environment variables
☐ Setup Redis for caching
☐ Configure database connection pooling
☐ Implement database transaction management
```

#### Week 2: Authentication System
**Deliverables:**
- Email verification flow
- Password reset system
- MFA setup & verification
- JWT token management
- Session management

**Tasks:**
```
Auth Service:
☐ Email verification token generation
☐ Email sending service (Nodemailer)
☐ Email template design
☐ Password reset flow
☐ MFA TOTP implementation
☐ MFA email OTP implementation
☐ MFA backup codes generation
☐ Refresh token management
☐ Session token storage & retrieval
☐ Token expiration handling
☐ Login endpoint update
☐ Signup endpoint update
☐ MFA verification endpoint
☐ Forgot password endpoint
☐ Reset password endpoint

Frontend (Flutter):
☐ Email verification UI
☐ MFA setup screen
☐ MFA verification screen
☐ Password reset UI
☐ Integration with auth service
```

#### Week 3: Security Hardening
**Deliverables:**
- Rate limiting
- CORS configuration
- API security headers
- Input validation middleware
- Audit logging

**Tasks:**
```
Backend:
☐ Implement rate limiting middleware
☐ Configure CORS (whitelist origins)
☐ Add security headers (helmet)
☐ Input validation on all endpoints
☐ SQL injection prevention
☐ XSS prevention (sanitization)
☐ CSRF protection
☐ Admin audit logging
☐ User activity logging
☐ Secure password hashing (bcrypt cost 12)
☐ Remove hardcoded API keys
☐ Environment variable configuration
☐ Database encryption for sensitive fields

Testing:
☐ Security penetration testing
☐ Vulnerability scanning
☐ Rate limit testing
☐ CORS testing
```

### Phase 2: User Profile & Trip Management (Weeks 4-6)

#### Week 4: Enhanced User Profiles
**Deliverables:**
- Complete user profile system
- Emergency contact management
- User preferences
- Accessibility settings

**Tasks:**
```
Backend:
☐ User profile update endpoints
☐ Emergency contact CRUD
☐ Preference management
☐ Accessibility settings
☐ User profile serialization
☐ Profile picture upload
☐ Validation rules

Frontend (Flutter):
☐ Profile edit screen
☐ Emergency contact management
☐ Preference settings
☐ Accessibility settings UI
☐ Profile picture upload
```

#### Week 5: Trip Management System
**Deliverables:**
- Trip creation & management
- Trip participant management
- Itinerary management
- Trip status tracking

**Tasks:**
```
Backend:
☐ Trip creation endpoint
☐ Trip update endpoint
☐ Trip list endpoint (with filters)
☐ Trip detail endpoint
☐ Trip deletion endpoint
☐ Participant invitation endpoint
☐ Participant acceptance endpoint
☐ Participant removal endpoint
☐ Itinerary CRUD endpoints
☐ Trip status update endpoint
☐ Permission validation (organizer only)
☐ Trip expense endpoints

Frontend (Flutter):
☐ Create trip screen
☐ Trip list screen
☐ Trip details screen
☐ Trip members screen
☐ Invite members UI
☐ Itinerary management screen
☐ Trip status display
☐ Real-time update for group changes

Testing:
☐ Trip lifecycle testing
☐ Permission testing
☐ Multi-user trip scenarios
```

#### Week 6: Live Location & Tracking
**Deliverables:**
- Real-time location tracking
- Live map
- Location history
- Geofencing

**Tasks:**
```
Backend:
☐ Live location update endpoint
☐ Location history endpoint
☐ Geofence creation/update
☐ Geofence alert triggering
☐ Socket.io location broadcasting
☐ Location query optimization

Frontend (Flutter):
☐ Live map screen implementation
☐ Real-time location updates (Socket.io)
☐ Group member locations
☐ Location sharing toggle
☐ Location history view
☐ Geofence visualization
☐ Geofence entry/exit alerts

Testing:
☐ Real-time location accuracy
☐ Socket.io performance
☐ Location history queries
☐ Geofence boundary testing
```

### Phase 3: Safety & Emergency (Weeks 7-8)

#### Week 7: Emergency & Safety System
**Deliverables:**
- SOS activation
- Emergency alerts
- Safety incident reporting
- Risk score calculation

**Tasks:**
```
Backend:
☐ Emergency event creation
☐ SOS notification system
☐ Emergency contact notification
☐ Authority notification (optional)
☐ Safety incident reporting endpoint
☐ Safety incident list endpoint
☐ Risk score calculation algorithm
☐ Risk score caching
☐ Safety alert generation

Frontend (Flutter):
☐ Emergency SOS screen
☐ SOS button implementation
☐ SOS confirmation dialog
☐ Emergency contact display
☐ SOS status monitoring
☐ Safety score display
☐ Risk alert display
☐ Incident report form

Testing:
☐ SOS notification accuracy
☐ Contact notification delivery
☐ Risk score calculations
☐ Alert generation and timing
```

#### Week 8: Safety Monitoring & Alerts
**Deliverables:**
- Weather-based alerts
- Incident tracking
- Safety recommendations
- Real-time alert system

**Tasks:**
```
Backend:
☐ Weather alert integration
☐ Alert triggering logic
☐ Alert notification service
☐ Safety incident analytics
☐ Risk assessment API
☐ Recommendation engine integration

Frontend (Flutter):
☐ Alert notification display
☐ Safety information screen
☐ Alert history
☐ Recommendation display

Testing:
☐ Alert accuracy
☐ Alert timing
☐ Multi-alert handling
☐ Alert delivery verification
```

### Phase 4: Payments & Booking (Weeks 9-10)

#### Week 9: Payment Integration
**Deliverables:**
- Stripe/Razorpay integration
- Booking system
- Payment processing
- Invoice generation

**Tasks:**
```
Backend:
☐ Payment gateway SDK integration
☐ Payment intent creation
☐ Payment webhook handling
☐ Payment status tracking
☐ Invoice generation
☐ Receipt email sending
☐ Refund processing
☐ Payment history endpoint

Frontend (Flutter):
☐ Booking screen
☐ Payment method selection
☐ Payment processing UI
☐ Payment confirmation
☐ Receipt display
☐ Payment history

Testing:
☐ Test payment processing
☐ Webhook testing
☐ Invoice generation
☐ Refund scenarios
```

#### Week 10: Expense Splitting
**Deliverables:**
- Trip expense tracking
- Expense splitting algorithm
- Settlement tracking
- Financial reports

**Tasks:**
```
Backend:
☐ Expense creation endpoint
☐ Expense split calculation
☐ Settlement tracking
☐ Financial report generation
☐ Expense history

Frontend (Flutter):
☐ Expense entry screen
☐ Expense split display
☐ Settlement requests
☐ Financial summary

Testing:
☐ Split calculation accuracy
☐ Settlement logic
☐ Edge cases (refunds, etc.)
```

### Phase 5: AI & Wellness (Weeks 11-12)

#### Week 11: AI Travel Assistant Upgrade
**Deliverables:**
- Backend AI integration
- Context-aware responses
- Chat history management
- Recommendation system

**Tasks:**
```
Backend:
☐ AI service integration (Groq backend)
☐ Context extraction from trip data
☐ Response caching
☐ Conversation management
☐ Recommendation scoring
☐ Travel tips database
☐ Safety advisory system

Frontend (Flutter):
☐ Chat interface enhancement
☐ Context display
☐ Response ratings
☐ Recommendation UI

Testing:
☐ AI response quality
☐ Context accuracy
☐ Performance testing
```

#### Week 12: Mental Health & Admin Panel
**Deliverables:**
- Mental health chatbot
- Wellness check-ins
- Admin dashboard
- Analytics system

**Tasks:**
```
Backend:
☐ Mental health chat service
☐ Wellness scoring
☐ Daily check-in logic
☐ Crisis detection
☐ Admin dashboard APIs
☐ Analytics event tracking
☐ Report generation

Frontend (Flutter):
☐ Mental health chat screen
☐ Daily check-in form
☐ Wellness resources
☐ Mood tracker

Admin Dashboard (Web):
☐ Dashboard overview
☐ User management interface
☐ Trip monitoring
☐ Safety dashboard
☐ Financial reports
☐ Analytics dashboard
☐ Admin logs viewer

Testing:
☐ Mental health response accuracy
☐ Admin dashboard functionality
☐ Analytics data accuracy
☐ Report generation
```

## Development Team Structure

```
TEAM COMPOSITION (3 people):

1. BACKEND LEAD (Node.js/Database)
   - Weeks 1-12: Core API development
   - Deliverables: All backend services
   - Skills: Node.js, MySQL, API design, Security
   - Estimated Hours: 600

2. FRONTEND LEAD (Flutter)
   - Weeks 1-12: Mobile app development
   - Deliverables: All Flutter screens
   - Skills: Flutter, Dart, UI/UX, Integration
   - Estimated Hours: 550

3. FULLSTACK ENGINEER (DevOps/Admin)
   - Weeks 1-3: Database setup, security
   - Weeks 4-6: Payment integration
   - Weeks 7-12: Admin panel, deployment
   - Skills: DevOps, Admin panel, Web dev, Deployment
   - Estimated Hours: 450

TOTAL: 1,600 developer hours (3 months)
```

---

# PHASE-BY-PHASE IMPLEMENTATION GUIDE

## Phase 1 Implementation Details (Weeks 1-3)

### Database Migration Script
```sql
-- Run this in order:

-- 1. Create new roles
INSERT INTO roles (role_id, role_name, description) VALUES
(1, 'Traveler', 'Regular user'),
(2, 'Organizer', 'Trip organizer'),
(3, 'Admin', 'Platform administrator');

-- 2. Create permissions
INSERT INTO permissions (permission_id, permission_name, resource, action) VALUES
(1, 'create_trip', 'trips', 'create'),
(2, 'edit_own_trip', 'trips', 'edit'),
(3, 'delete_own_trip', 'trips', 'delete'),
(4, 'view_all_trips', 'trips', 'view'),
(5, 'manage_users', 'users', 'manage'),
(6, 'view_analytics', 'analytics', 'view'),
(7, 'manage_payments', 'payments', 'manage');

-- 3. Assign permissions to roles
INSERT INTO role_permissions (role_id, permission_id) VALUES
(1, 1), (1, 2), (1, 3),
(2, 1), (2, 2), (2, 3), (2, 4),
(3, 4), (3, 5), (3, 6), (3, 7);

-- 4. Migrate existing users to new roles
ALTER TABLE users ADD COLUMN role_id INT DEFAULT 1;
UPDATE users SET role_id = 1;
ALTER TABLE users MODIFY role_id INT NOT NULL;
ALTER TABLE users ADD FOREIGN KEY (role_id) REFERENCES roles(role_id);

-- All 38 tables from schema above
```

### Week 1 Checklist
```
Database:
☑ All 38 tables created
☑ Foreign keys implemented
☑ Indexes created
☑ Data migrated from old schema
☑ Backup tested

Backend Setup:
☑ Redis configured
☑ Connection pooling enabled
☑ Environment variables set
☑ Database encryption keys set
☑ Logging configured

Testing:
☑ Database connectivity verified
☑ Query performance tested
☑ Backup/restore tested
```

### Email Service Setup
```javascript
// emailService.js
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail', // or SendGrid, AWS SES
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD
  }
});

const sendVerificationEmail = async (email, token) => {
  const verificationUrl = `${process.env.APP_URL}/verify-email?token=${token}`;
  
  const mailOptions = {
    from: process.env.EMAIL_FROM,
    to: email,
    subject: 'SafarSync Email Verification',
    html: `
      <h2>Welcome to SafarSync!</h2>
      <p>Click the link below to verify your email:</p>
      <a href="${verificationUrl}">Verify Email</a>
      <p>This link expires in 24 hours.</p>
    `
  };
  
  return transporter.sendMail(mailOptions);
};

module.exports = { sendVerificationEmail };
```

### MFA Implementation
```javascript
// mfaService.js
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');

const setupTOTP = async (user) => {
  const secret = speakeasy.generateSecret({
    name: `SafarSync (${user.email})`,
    issuer: 'SafarSync'
  });
  
  const qrCode = await QRCode.toDataURL(secret.otpauth_url);
  const backupCodes = generateBackupCodes();
  
  return { secret, qrCode, backupCodes };
};

const verifyTOTP = (token, secret) => {
  return speakeasy.totp.verify({
    secret: secret,
    encoding: 'base32',
    token: token,
    window: 2
  });
};

const generateBackupCodes = () => {
  const codes = [];
  for (let i = 0; i < 10; i++) {
    codes.push(Math.random().toString(36).substring(2, 10).toUpperCase());
  }
  return codes;
};
```

---

## Implementation Summary

**Total Development Effort:** 1,600 hours  
**Team Size:** 3 developers  
**Timeline:** 12 weeks (90 days)  
**Cost Estimate:** $50,000-80,000 USD (depending on rates)

**Key Success Factors:**
1. Parallel development of frontend/backend
2. Daily stand-ups for integration
3. Automated testing for each module
4. Weekly milestone reviews
5. Security audits at end of each phase

**Post-Development:**
- Week 13-14: Bug fixes & optimization
- Week 15-16: Final security audit & penetration testing
- Week 17-18: Performance testing & load testing
- Week 19-20: Deployment & production readiness

---

End of Master Implementation Plan

This plan provides developers with a complete, step-by-step blueprint for transforming SafarSync from 28% to 100% completion with production-grade quality.

