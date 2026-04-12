const path = require('path');
require('dotenv').config({
  path: path.resolve(__dirname, '..', '.env'),
});
const mysql = require('mysql2');

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

const updateSql = `
  UPDATE destination
  SET image_url = CONCAT('https://picsum.photos/seed/safarsync-', destinationId, '/1200/800')
  WHERE image_url IS NULL OR image_url = ''
`;

db.query(updateSql, (updateErr) => {
  if (updateErr) {
    console.error('Failed to seed destination images:', updateErr);
    db.end();
    process.exit(1);
  }

  db.query(
    'SELECT destinationId, name, image_url FROM destination ORDER BY destinationId DESC',
    (selectErr, rows) => {
      if (selectErr) {
        console.error('Failed to verify seeded images:', selectErr);
        db.end();
        process.exit(1);
      }

      console.log(JSON.stringify(rows, null, 2));
      db.end();
    },
  );
});
