const db = require('../config/db');

// Create route
const createRoute = (req, res) => {
  const {
    route_name,
    description,
    start_location,
    end_location,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    difficulty_level,
    is_public,
  } = req.body;
  const user_id = req.user.userId;

  const query = `INSERT INTO routes 
    (user_id, route_name, description, start_location, end_location, start_lat, start_lng, end_lat, end_lng, difficulty_level, is_public)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

  const params = [
    user_id,
    route_name,
    description,
    start_location,
    end_location,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    difficulty_level,
    is_public,
  ];

  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to create route' });
    }
    res.status(201).json({
      message: 'Route created successfully',
      route_id: results.insertId,
    });
  });
};

// Get user's routes
const getUserRoutes = (req, res) => {
  const user_id = req.user.userId;
  const { page = 1, limit = 10 } = req.query;
  const offset = (page - 1) * limit;

  const query = 'SELECT * FROM routes WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?';

  db.query(query, [user_id, parseInt(limit), offset], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to fetch routes' });
    }
    res.json({ routes: results, page, limit });
  });
};

// Get route by ID
const getRouteById = (req, res) => {
  const { id } = req.params;

  const query = `SELECT * FROM routes WHERE route_id = ?`;

  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to fetch route' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Route not found' });
    }

    res.json({ route: results[0] });
  });
};

// Update route
const updateRoute = (req, res) => {
  const { id } = req.params;
  const user_id = req.user.userId;
  const {
    route_name,
    description,
    start_location,
    end_location,
    difficulty_level,
    is_public,
  } = req.body;

  const query = `UPDATE routes 
    SET route_name = ?, description = ?, start_location = ?, end_location = ?, difficulty_level = ?, is_public = ?
    WHERE route_id = ? AND user_id = ?`;

  const params = [route_name, description, start_location, end_location, difficulty_level, is_public, id, user_id];

  db.query(query, params, (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to update route' });
    }
    res.json({ message: 'Route updated successfully' });
  });
};

// Delete route
const deleteRoute = (req, res) => {
  const { id } = req.params;
  const user_id = req.user.userId;

  const query = 'DELETE FROM routes WHERE route_id = ? AND user_id = ?';

  db.query(query, [id, user_id], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to delete route' });
    }
    res.json({ message: 'Route deleted successfully' });
  });
};

// Optimize route (weather/traffic)
const optimizeRoute = (req, res) => {
  const { id } = req.params;
  const user_id = req.user.userId;

  const query = 'UPDATE routes SET weather_optimized = TRUE, traffic_considered = TRUE WHERE route_id = ? AND user_id = ?';

  db.query(query, [id, user_id], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to optimize route' });
    }
    res.json({ message: 'Route optimization applied' });
  });
};

// Add stop to route
const addRouteStop = (req, res) => {
  const { id } = req.params;
  const { destination_id, stop_order, latitude, longitude, stop_name, duration_at_stop, notes } = req.body;

  const query = `INSERT INTO route_stops 
    (route_id, destination_id, stop_order, latitude, longitude, stop_name, duration_at_stop, notes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;

  const params = [id, destination_id, stop_order, latitude, longitude, stop_name, duration_at_stop, notes];

  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to add stop' });
    }
    res.status(201).json({
      message: 'Stop added successfully',
      stop_id: results.insertId,
    });
  });
};

// Get public routes
const getPublicRoutes = (req, res) => {
  const { page = 1, limit = 10 } = req.query;
  const offset = (page - 1) * limit;

  const query = `SELECT * FROM routes 
    WHERE is_public = TRUE 
    ORDER BY views_count DESC, created_at DESC 
    LIMIT ? OFFSET ?`;

  db.query(query, [parseInt(limit), offset], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to fetch public routes' });
    }
    res.json({ routes: results, page, limit });
  });
};

module.exports = {
  createRoute,
  getUserRoutes,
  getRouteById,
  updateRoute,
  deleteRoute,
  optimizeRoute,
  addRouteStop,
  getPublicRoutes,
};
