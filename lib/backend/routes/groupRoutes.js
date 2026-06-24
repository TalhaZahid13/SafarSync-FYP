const express = require('express');
const router  = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const db = require('../config/db');

// ─── helpers ──────────────────────────────────────────────────────────────────
const makeCode = () =>
  Math.random().toString(36).substring(2, 8).toUpperCase();

// ─── POST /create ─────────────────────────────────────────────────────────────
router.post('/create', authenticate, (req, res) => {
  const { group_name, description, max_members } = req.body;
  const userId = req.user.userId;

  if (!group_name || !group_name.trim()) {
    return res.status(400).json({ error: 'group_name is required' });
  }

  const invite_code = makeCode();

  db.query(
    `INSERT INTO group_bookings
       (trip_name, description, created_by, max_members, invite_code, status)
     VALUES (?, ?, ?, ?, ?, 'Open')`,
    [group_name.trim(), description || '', userId, max_members || 10, invite_code],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });

      const groupId = result.insertId;

      // Add creator as organizer
      db.query(
        `INSERT INTO group_booking_members (group_booking_id, user_id, role)
         VALUES (?, ?, 'organizer')`,
        [groupId, userId],
        (err2) => {
          if (err2) console.error('[groups] add organizer error:', err2.message);

          res.status(201).json({
            success:    true,
            group_id:   groupId,
            invite_code,
            group_name: group_name.trim(),
            message:    'Group created successfully',
          });
        }
      );
    }
  );
});

// ─── GET /my-groups ───────────────────────────────────────────────────────────
router.get('/my-groups', authenticate, (req, res) => {
  const userId = req.user.userId;

  db.query(
    `SELECT DISTINCT
       gb.group_booking_id AS group_id,
       gb.trip_name        AS group_name,
       gb.description,
       gb.invite_code,
       gb.status,
       gb.max_members,
       gb.created_by,
       gb.created_at,
       gbm_me.role         AS my_role,
       u.full_name         AS creator_name,
       (SELECT COUNT(*) FROM group_booking_members
        WHERE group_booking_id = gb.group_booking_id) AS member_count
     FROM group_bookings gb
     JOIN group_booking_members gbm_me
          ON gbm_me.group_booking_id = gb.group_booking_id
         AND gbm_me.user_id = ?
     LEFT JOIN users u ON u.user_id = gb.created_by
     ORDER BY gb.created_at DESC`,
    [userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, groups: rows || [] });
    }
  );
});

// ─── GET /:group_id/members ───────────────────────────────────────────────────
router.get('/:group_id/members', authenticate, (req, res) => {
  const { group_id } = req.params;

  db.query(
    `SELECT
       u.user_id, u.full_name, u.email,
       u.profile_picture_url,
       gbm.role, gbm.joined_at
     FROM group_booking_members gbm
     JOIN users u ON u.user_id = gbm.user_id
     WHERE gbm.group_booking_id = ?
     ORDER BY gbm.joined_at ASC`,
    [group_id],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, members: rows || [] });
    }
  );
});

// ─── GET /:group_id ───────────────────────────────────────────────────────────
router.get('/:group_id', authenticate, (req, res) => {
  const { group_id } = req.params;

  db.query(
    `SELECT
       gb.group_booking_id AS group_id,
       gb.trip_name        AS group_name,
       gb.description,
       gb.invite_code,
       gb.status,
       gb.max_members,
       gb.created_by,
       gb.created_at,
       u.full_name AS creator_name,
       (SELECT COUNT(*) FROM group_booking_members
        WHERE group_booking_id = gb.group_booking_id) AS member_count
     FROM group_bookings gb
     LEFT JOIN users u ON u.user_id = gb.created_by
     WHERE gb.group_booking_id = ?`,
    [group_id],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!rows.length) return res.status(404).json({ error: 'Group not found' });

      db.query(
        `SELECT u.user_id, u.full_name, u.email,
                u.profile_picture_url, gbm.role, gbm.joined_at
         FROM group_booking_members gbm
         JOIN users u ON u.user_id = gbm.user_id
         WHERE gbm.group_booking_id = ?
         ORDER BY gbm.joined_at ASC`,
        [group_id],
        (err2, members) => {
          if (err2) return res.status(500).json({ error: err2.message });
          res.json({ success: true, group: rows[0], members: members || [] });
        }
      );
    }
  );
});

// ─── POST /join ───────────────────────────────────────────────────────────────
router.post('/join', authenticate, (req, res) => {
  const { invite_code } = req.body;
  const userId = req.user.userId;

  if (!invite_code) {
    return res.status(400).json({ error: 'invite_code is required' });
  }

  db.query(
    `SELECT group_booking_id, trip_name, max_members,
            (SELECT COUNT(*) FROM group_booking_members
             WHERE group_booking_id = gb.group_booking_id) AS member_count
     FROM group_bookings gb
     WHERE invite_code = ?`,
    [invite_code.trim().toUpperCase()],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!rows.length) return res.status(404).json({ error: 'Invalid invite code' });

      const { group_booking_id, trip_name, max_members, member_count } = rows[0];

      if (member_count >= max_members) {
        return res.status(400).json({ error: 'Group is full' });
      }

      db.query(
        `INSERT INTO group_booking_members (group_booking_id, user_id, role)
         VALUES (?, ?, 'member')`,
        [group_booking_id, userId],
        (err2) => {
          if (err2) {
            if (err2.code === 'ER_DUP_ENTRY') {
              return res.status(400).json({ error: 'Already a member of this group' });
            }
            return res.status(500).json({ error: err2.message });
          }
          res.json({
            success:   true,
            group_id:  group_booking_id,
            group_name: trip_name,
            message:   'Joined group successfully',
          });
        }
      );
    }
  );
});

// ─── POST /:group_id/invite ───────────────────────────────────────────────────
router.post('/:group_id/invite', authenticate, (req, res) => {
  const { group_id } = req.params;
  const { receiver_id } = req.body;
  const senderId = req.user.userId;

  if (!receiver_id) {
    return res.status(400).json({ error: 'receiver_id is required' });
  }

  // Check sender is a member
  db.query(
    `SELECT 1 FROM group_booking_members
     WHERE group_booking_id = ? AND user_id = ?`,
    [group_id, senderId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!rows.length) return res.status(403).json({ error: 'You are not a member of this group' });

      db.query(
        `INSERT INTO group_invitations
           (group_booking_id, sender_id, receiver_id, status)
         VALUES (?, ?, ?, 'pending')`,
        [group_id, senderId, receiver_id],
        (err2) => {
          if (err2) {
            if (err2.code === 'ER_DUP_ENTRY') {
              return res.status(400).json({ error: 'Invitation already sent' });
            }
            return res.status(500).json({ error: err2.message });
          }
          res.json({ success: true, message: 'Invitation sent' });
        }
      );
    }
  );
});

// ─── DELETE /:group_id/members/:user_id ──────────────────────────────────────
router.delete('/:group_id/members/:user_id', authenticate, (req, res) => {
  const { group_id, user_id } = req.params;
  const requesterId = req.user.userId;

  // Allow self-removal or organizer removal
  db.query(
    `SELECT role FROM group_booking_members
     WHERE group_booking_id = ? AND user_id = ?`,
    [group_id, requesterId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      const requesterRole = rows[0]?.role;
      const isSelf       = String(requesterId) === String(user_id);
      if (!isSelf && requesterRole !== 'organizer') {
        return res.status(403).json({ error: 'Only organizers can remove members' });
      }

      db.query(
        `DELETE FROM group_booking_members
         WHERE group_booking_id = ? AND user_id = ?`,
        [group_id, user_id],
        (err2, r) => {
          if (err2) return res.status(500).json({ error: err2.message });
          if (r.affectedRows === 0) {
            return res.status(404).json({ error: 'Member not found' });
          }
          res.json({ success: true, message: 'Member removed' });
        }
      );
    }
  );
});

module.exports = router;
