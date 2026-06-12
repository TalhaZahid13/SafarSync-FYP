const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const db = require('../config/db');

// Create group
router.post('/create', authenticate, (req, res) => {
  const { group_name, description } = req.body;
  const created_by_id = req.user.userId;
  const invite_code = Math.random().toString(36).substring(7).toUpperCase();

  const query = `
    INSERT INTO groups (group_name, created_by_id, invite_code, description)
    VALUES (?, ?, ?, ?)
  `;

  db.query(query, [group_name, created_by_id, invite_code, description], (err, result) => {
    if (err) {
      console.error('Group creation error:', err);
      return res.status(500).json({ error: err.message });
    }

    const groupId = result.insertId;

    // Add creator as member
    db.query(
      'INSERT INTO group_members (group_id, user_id) VALUES (?, ?)',
      [groupId, created_by_id],
      (err) => {
        if (err) console.error('Error adding creator:', err);
      }
    );

    res.status(201).json({
      success: true,
      group_id: groupId,
      invite_code: invite_code,
      message: 'Group created successfully'
    });
  });
});

// Get user's groups
router.get('/my-groups', authenticate, (req, res) => {
  const user_id = req.user.userId;

  const query = `
    SELECT DISTINCT g.* FROM groups g
    LEFT JOIN group_members gm ON g.group_id = gm.group_id
    WHERE gm.user_id = ? OR g.created_by_id = ?
    ORDER BY g.created_at DESC
  `;

  db.query(query, [user_id, user_id], (err, results) => {
    if (err) {
      console.error('Groups fetch error:', err);
      return res.status(500).json({ error: err.message });
    }
    res.json({ success: true, groups: results || [] });
  });
});

// Get group details with members
router.get('/:group_id', (req, res) => {
  const { group_id } = req.params;

  const groupQuery = `SELECT * FROM groups WHERE group_id = ?`;
  const membersQuery = `
    SELECT u.user_id, u.full_name, u.profile_picture_url
    FROM group_members gm
    JOIN users u ON gm.user_id = u.user_id
    WHERE gm.group_id = ?
  `;

  db.query(groupQuery, [group_id], (err, groupResults) => {
    if (err) return res.status(500).json({ error: err.message });
    if (groupResults.length === 0) return res.status(404).json({ error: 'Group not found' });

    db.query(membersQuery, [group_id], (err, members) => {
      if (err) return res.status(500).json({ error: err.message });

      res.json({
        success: true,
        group: groupResults[0],
        members: members || []
      });
    });
  });
});

// Join group with code
router.post('/join', authenticate, (req, res) => {
  const { invite_code } = req.body;
  const user_id = req.user.userId;

  const query = `SELECT group_id FROM groups WHERE invite_code = ?`;

  db.query(query, [invite_code], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0) return res.status(404).json({ error: 'Invalid invite code' });

    const group_id = results[0].group_id;

    db.query(
      'INSERT INTO group_members (group_id, user_id) VALUES (?, ?)',
      [group_id, user_id],
      (err) => {
        if (err) {
          if (err.code === 'ER_DUP_ENTRY') {
            return res.status(400).json({ error: 'Already a member' });
          }
          return res.status(500).json({ error: err.message });
        }
        res.json({ success: true, message: 'Joined group successfully' });
      }
    );
  });
});

module.exports = router;
