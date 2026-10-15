const mysql = require('mysql2');
require('dotenv').config();

const db = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Without this, mysql2 returns DECIMAL/NEWDECIMAL columns (price, cost,
  // rating, latitude, longitude, amount, ...) as strings, not numbers —
  // causing "type 'String' is not a subtype of type 'num?'" crashes in
  // Flutter wherever a response field is cast with `as num` / `as double`.
  decimalNumbers: true,
  // Most hosted MySQL providers (Aiven, PlanetScale, TiDB Cloud, Railway
  // public proxy) require TLS. Set DB_SSL=true for those.
  ...(process.env.DB_SSL === 'true'
    ? { ssl: { rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false' } }
    : {}),
});

db.getConnection((err, connection) => {
  if (err) {
    console.error('Error connecting to the database:', err);
    return;
  }
  console.log('Connected to the database');

  const ensureDestinationsTableQuery = `
    CREATE TABLE IF NOT EXISTS destinations (
      destination_id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      description TEXT,
      latitude DECIMAL(10, 8) NULL,
      longitude DECIMAL(11, 8) NULL,
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
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `;

  connection.query(ensureDestinationsTableQuery, (tableErr) => {
    if (tableErr) {
      console.error('Error ensuring destinations table:', tableErr);
    }
  });

  const ensureUserLocationUpdatesTableQuery = `
    CREATE TABLE IF NOT EXISTS user_location_updates (
      location_update_id INT AUTO_INCREMENT PRIMARY KEY,
      user_identifier VARCHAR(128) NULL,
      latitude DECIMAL(10, 8) NOT NULL,
      longitude DECIMAL(11, 8) NOT NULL,
      city VARCHAR(100) NULL,
      country VARCHAR(100) NULL,
      accuracy_meters DECIMAL(10, 2) NULL,
      captured_at DATETIME NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_user_identifier (user_identifier),
      INDEX idx_captured_at (captured_at)
    )
  `;

  connection.query(ensureUserLocationUpdatesTableQuery, (tableErr) => {
    if (tableErr) {
      console.error('Error ensuring user_location_updates table:', tableErr);
    }
  });

  const ensureLegacyDestinationColumnsQueries = [
    'ALTER TABLE destination ADD COLUMN IF NOT EXISTS image_url VARCHAR(500) NULL',
    'ALTER TABLE destination ADD COLUMN IF NOT EXISTS rating DECIMAL(3, 2) NULL',
    'ALTER TABLE destination ADD COLUMN IF NOT EXISTS review_count INT DEFAULT 0',
    'ALTER TABLE destination ADD COLUMN IF NOT EXISTS average_cost DECIMAL(10, 2) NULL',
  ];

  const ensureTravelerLocationColumnsQueries = [
    'ALTER TABLE Traveler ADD COLUMN IF NOT EXISTS lastLocation VARCHAR(255) NULL',
    'ALTER TABLE Traveler ADD COLUMN IF NOT EXISTS last_location VARCHAR(255) NULL',
    'ALTER TABLE Traveler ADD COLUMN IF NOT EXISTS last_latitude DECIMAL(10, 8) NULL',
    'ALTER TABLE Traveler ADD COLUMN IF NOT EXISTS last_longitude DECIMAL(11, 8) NULL',
    'ALTER TABLE Traveler ADD COLUMN IF NOT EXISTS lastLocationUpdatedAt DATETIME NULL',
    'ALTER TABLE Traveler ADD COLUMN IF NOT EXISTS last_location_updated_at DATETIME NULL',
  ];

  const ensureBookingPaymentColumnsQueries = [
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'Unpaid'",
    'ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_intent_id VARCHAR(255) NULL',
  ];

  ensureBookingPaymentColumnsQueries.forEach((sql) => {
    connection.query(sql, (alterErr) => {
      if (alterErr) {
        console.error('Error ensuring booking payment columns:', alterErr);
      }
    });
  });

  ensureLegacyDestinationColumnsQueries.forEach((sql) => {
    connection.query(sql, (alterErr) => {
      if (alterErr) {
        console.error('Error ensuring legacy destination columns:', alterErr);
      }
    });
  });

  ensureTravelerLocationColumnsQueries.forEach((sql) => {
    connection.query(sql, (alterErr) => {
      if (alterErr) {
        console.error('Error ensuring Traveler location columns:', alterErr);
      }
    });
  });

  connection.release(); 
});

module.exports = db;
