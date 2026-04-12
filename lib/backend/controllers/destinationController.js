const db = require('../config/db');

// Get all destinations with pagination and filters
const getAllDestinations = (req, res) => {
  const { page = 1, limit = 10, category, city, country } = req.query;
  const parsedPage = parseInt(page, 10) || 1;
  const parsedLimit = parseInt(limit, 10) || 10;
  const offset = (parsedPage - 1) * parsedLimit;

  let query = `
    SELECT
      destinationId AS id,
      name,
      region AS location,
      region AS country,
      NULL AS city,
      NULL AS category,
      NULL AS description,
      COALESCE(image_url, 'https://via.placeholder.com/400') AS image_url,
      COALESCE(rating, 4.5) AS rating,
      COALESCE(review_count, 0) AS review_count,
      average_cost
    FROM destination
    WHERE 1=1
  `;
  const params = [];

  // Legacy SQLyog schema does not have category/city/country columns.
  // Use region as a loose match for city/country filters.
  if (city) {
    query += ' AND region = ?';
    params.push(city);
  }
  if (country) {
    query += ' AND region = ?';
    params.push(country);
  }
  if (category) {
    query += ' AND ? IS NOT NULL';
    params.push(category);
  }

  query += ' ORDER BY destinationId DESC LIMIT ? OFFSET ?';
  params.push(parsedLimit, offset);

  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.json({ destinations: results, page: parsedPage, limit: parsedLimit });
  });
};

// Search destinations by name or description
const searchDestinations = (req, res) => {
  const { query } = req.query;

  if (!query || query.length < 2) {
    return res.status(400).json({ error: 'Search query must be at least 2 characters' });
  }

  const searchQuery = `
    SELECT
      destinationId AS id,
      name,
      region AS location,
      region AS country,
      NULL AS city,
      NULL AS category,
      NULL AS description,
      COALESCE(image_url, 'https://via.placeholder.com/400') AS image_url,
      COALESCE(rating, 4.5) AS rating,
      COALESCE(review_count, 0) AS review_count,
      average_cost
    FROM destination
    WHERE name LIKE ? OR region LIKE ?
    ORDER BY destinationId DESC
    LIMIT 20
  `;

  const likeQuery = `%${query}%`;

  db.query(searchQuery, [likeQuery, likeQuery], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.json({ results });
  });
};

// Get destination by ID
const getDestinationById = (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT
      destinationId AS id,
      name,
      region AS location,
      region AS country,
      coordinates,
      has3DTour,
      COALESCE(image_url, 'https://via.placeholder.com/400') AS image_url,
      COALESCE(rating, 4.5) AS rating,
      COALESCE(review_count, 0) AS review_count,
      average_cost
    FROM destination
    WHERE destinationId = ?
  `;

  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Destination not found' });
    }

    res.json({ destination: results[0] });
  });
};

// Create destination (admin)
const createDestination = (req, res) => {
  const {
    name,
    region,
    coordinates,
    has3DTour = 0,
    image_url,
    rating,
    review_count,
    average_cost,
  } = req.body;

  const query = `
    INSERT INTO destination
      (name, coordinates, region, has3DTour, image_url, rating, review_count, average_cost)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `;

  const params = [
    name,
    coordinates ?? null,
    region ?? null,
    has3DTour ? 1 : 0,
    image_url ?? null,
    rating ?? null,
    review_count ?? 0,
    average_cost ?? null,
  ];

  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.status(201).json({
      message: 'Destination created successfully',
      destination_id: results.insertId,
    });
  });
};

// Update destination
const updateDestination = (req, res) => {
  const { id } = req.params;
  const {
    name,
    region,
    coordinates,
    has3DTour,
    image_url,
    rating,
    review_count,
    average_cost,
  } = req.body;

  const query = `
    UPDATE destination
    SET name = ?, region = ?, coordinates = ?, has3DTour = ?, image_url = ?, rating = ?, review_count = ?, average_cost = ?
    WHERE destinationId = ?
  `;

  const params = [
    name,
    region ?? null,
    coordinates ?? null,
    has3DTour ? 1 : 0,
    image_url ?? null,
    rating ?? null,
    review_count ?? 0,
    average_cost ?? null,
    id,
  ];

  db.query(query, params, (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.json({ message: 'Destination updated successfully' });
  });
};

// Delete destination
const deleteDestination = (req, res) => {
  const { id } = req.params;

  const query = 'DELETE FROM destination WHERE destinationId = ?';

  db.query(query, [id], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.json({ message: 'Destination deleted successfully' });
  });
};

// Get destinations by category
const getDestinationsByCategory = (req, res) => {
  const { category } = req.params;
  const { page = 1, limit = 10 } = req.query;
  const parsedPage = parseInt(page, 10) || 1;
  const parsedLimit = parseInt(limit, 10) || 10;
  const offset = (parsedPage - 1) * parsedLimit;

  const query = `
    SELECT destinationId AS id, name, region AS location, region AS country
    FROM destination
    WHERE ? IS NOT NULL
    ORDER BY destinationId DESC
    LIMIT ? OFFSET ?
  `;

  db.query(query, [category, parsedLimit, offset], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.json({ destinations: results, category, page: parsedPage, limit: parsedLimit });
  });
};

// Get popular destinations
const getPopularDestinations = (req, res) => {
  const query = `
    SELECT
      destinationId AS id,
      name,
      region AS location,
      region AS country,
      has3DTour,
      COALESCE(image_url, 'https://via.placeholder.com/400') AS image_url,
      COALESCE(rating, 4.5) AS rating,
      COALESCE(review_count, 0) AS review_count,
      average_cost
    FROM destination
    ORDER BY COALESCE(rating, 0) DESC, has3DTour DESC, destinationId DESC
    LIMIT 20
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.json({ destinations: results });
  });
};

module.exports = {
  getAllDestinations,
  searchDestinations,
  getDestinationById,
  createDestination,
  updateDestination,
  deleteDestination,
  getDestinationsByCategory,
  getPopularDestinations,
};
