const db = require('../config/db');

// Get user's wishlist
const getWishlist = (req, res) => {
  const user_id = req.user.userId;
  const { page = 1, limit = 10 } = req.query;
  const offset = (page - 1) * limit;

  const query = `SELECT w.*, d.* FROM wishlists w
    JOIN destinations d ON w.destination_id = d.destination_id
    WHERE w.user_id = ?
    ORDER BY w.created_at DESC
    LIMIT ? OFFSET ?`;

  db.query(query, [user_id, parseInt(limit), offset], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to fetch wishlist' });
    }
    res.json({ wishlist: results, page, limit });
  });
};

// Add to wishlist
const addToWishlist = (req, res) => {
  const user_id = req.user.userId;
  const { destination_id, notes, priority, planned_visit_date } = req.body;

  if (!destination_id) {
    return res.status(400).json({ error: 'destination_id is required' });
  }

  const query = `INSERT INTO wishlists 
    (user_id, destination_id, notes, priority, planned_visit_date)
    VALUES (?, ?, ?, ?, ?)`;

  db.query(query, [user_id, destination_id, notes, priority, planned_visit_date], (err, results) => {
    if (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ error: 'Destination already in wishlist' });
      }
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to add to wishlist' });
    }
    res.status(201).json({
      message: 'Added to wishlist',
      wishlist_id: results.insertId,
    });
  });
};

// Remove from wishlist
const removeFromWishlist = (req, res) => {
  const user_id = req.user.userId;
  const { destinationId } = req.params;

  const query = 'DELETE FROM wishlists WHERE user_id = ? AND destination_id = ?';

  db.query(query, [user_id, destinationId], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to remove from wishlist' });
    }
    res.json({ message: 'Removed from wishlist' });
  });
};

// Check if destination is in wishlist
const checkInWishlist = (req, res) => {
  const user_id = req.user.userId;
  const { destinationId } = req.params;

  const query = 'SELECT * FROM wishlists WHERE user_id = ? AND destination_id = ?';

  db.query(query, [user_id, destinationId], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to check wishlist' });
    }
    res.json({ inWishlist: results.length > 0 });
  });
};

// Update wishlist item
const updateWishlistItem = (req, res) => {
  const user_id = req.user.userId;
  const { destinationId } = req.params;
  const { notes, priority, planned_visit_date } = req.body;

  const query = `UPDATE wishlists 
    SET notes = ?, priority = ?, planned_visit_date = ?
    WHERE user_id = ? AND destination_id = ?`;

  db.query(query, [notes, priority, planned_visit_date, user_id, destinationId], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to update wishlist item' });
    }
    res.json({ message: 'Wishlist item updated' });
  });
};

module.exports = {
  getWishlist,
  addToWishlist,
  removeFromWishlist,
  checkInWishlist,
  updateWishlistItem,
};
