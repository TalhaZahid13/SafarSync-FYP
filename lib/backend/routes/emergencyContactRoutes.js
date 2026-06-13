const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticate } = require('../middleware/authMiddleware');

// GET /api/emergency-contacts
router.get('/', authenticate, (req, res) => {
  const userId = req.user.userId;
  db.query(
    'SELECT * FROM emergency_contacts WHERE user_id = ? ORDER BY is_primary DESC, contact_id ASC',
    [userId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: err.message });
      res.json({ success: true, contacts: rows || [] });
    }
  );
});

// POST /api/emergency-contacts
router.post('/', authenticate, (req, res) => {
  const userId = req.user.userId;
  const { contact_name, contact_phone, contact_email, relationship, is_primary } = req.body;

  if (!contact_name || !contact_phone) {
    return res.status(400).json({ success: false, message: 'contact_name and contact_phone are required' });
  }

  // If setting as primary, clear existing primary first
  const upsert = () => {
    db.query(
      `INSERT INTO emergency_contacts (user_id, contact_name, contact_phone, contact_email, relationship, is_primary)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, contact_name, contact_phone, contact_email || null, relationship || null, is_primary ? 1 : 0],
      (err, result) => {
        if (err) return res.status(500).json({ success: false, message: err.message });
        res.status(201).json({ success: true, contact_id: result.insertId });
      }
    );
  };

  if (is_primary) {
    db.query(
      'UPDATE emergency_contacts SET is_primary = 0 WHERE user_id = ?',
      [userId],
      (err) => { if (err) console.error('[EmergencyContact] Clear primary error:', err.message); upsert(); }
    );
  } else {
    upsert();
  }
});

// PUT /api/emergency-contacts/:id
router.put('/:id', authenticate, (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;
  const { contact_name, contact_phone, contact_email, relationship, is_primary } = req.body;

  const doUpdate = () => {
    db.query(
      `UPDATE emergency_contacts
       SET contact_name = ?, contact_phone = ?, contact_email = ?, relationship = ?, is_primary = ?
       WHERE contact_id = ? AND user_id = ?`,
      [contact_name, contact_phone, contact_email || null, relationship || null, is_primary ? 1 : 0, id, userId],
      (err, result) => {
        if (err) return res.status(500).json({ success: false, message: err.message });
        if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Contact not found' });
        res.json({ success: true });
      }
    );
  };

  if (is_primary) {
    db.query(
      'UPDATE emergency_contacts SET is_primary = 0 WHERE user_id = ?',
      [userId],
      (err) => { if (err) console.error('[EmergencyContact] Clear primary error:', err.message); doUpdate(); }
    );
  } else {
    doUpdate();
  }
});

// DELETE /api/emergency-contacts/:id
router.delete('/:id', authenticate, (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;
  db.query(
    'DELETE FROM emergency_contacts WHERE contact_id = ? AND user_id = ?',
    [id, userId],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, message: err.message });
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Contact not found' });
      res.json({ success: true });
    }
  );
});

module.exports = router;
