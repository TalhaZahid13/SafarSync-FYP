const mysql = require('mysql2');
require('dotenv').config();

// Create the database connection pool
const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Example of how you can use the db connection
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

  const ensureLegacyDestinationColumnsQueries = [
    'ALTER TABLE destination ADD COLUMN IF NOT EXISTS image_url VARCHAR(500) NULL',
    'ALTER TABLE destination ADD COLUMN IF NOT EXISTS rating DECIMAL(3, 2) NULL',
    'ALTER TABLE destination ADD COLUMN IF NOT EXISTS review_count INT DEFAULT 0',
    'ALTER TABLE destination ADD COLUMN IF NOT EXISTS average_cost DECIMAL(10, 2) NULL',
  ];

  ensureLegacyDestinationColumnsQueries.forEach((sql) => {
    connection.query(sql, (alterErr) => {
      if (alterErr) {
        console.error('Error ensuring legacy destination columns:', alterErr);
      }
    });
  });

  connection.release();  // Always release the connection after using it
});

// Export the database pool so that it can be used across the app
module.exports = db;
