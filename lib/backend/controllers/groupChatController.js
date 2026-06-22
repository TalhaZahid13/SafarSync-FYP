const db = require('../config/db');
const getMessages = (req, res) => {
  const { groupId } = req.params;
  const userId = req.user.userId;
  const limit = parseInt(req.query.limit) || 50;
  const before = req.query.before;
  db.query(
    'SELECT 1 FROM group_booking_members WHERE group_booking_id = ? AND user_id = ? LIMIT 1',
    [groupId, userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (!rows || rows.length === 0) return res.status(403).json({ error: 'Not a member of this group' });

      let query = `
        SELECT gcm.message_id, gcm.group_booking_id, gcm.user_id,
               gcm.message, gcm.message_type, gcm.created_at,
               u.full_name AS sender_name, u.profile_picture_url AS sender_avatar
        FROM group_chat_messages gcm
        JOIN users u ON gcm.user_id = u.user_id
        WHERE gcm.group_booking_id = ?
      `;
      const params = [groupId];

      if (before) {
        query += ' AND gcm.message_id < ?';
        params.push(before);
      }

      query += ' ORDER BY gcm.created_at DESC LIMIT ?';
      params.push(limit);

      db.query(query, params, (err2, rows2) => {
        if (err2) return res.status(500).json({ error: 'Database error' });
        res.json({ success: true, messages: (rows2 || []).reverse() });
      });
    }
  );
};

const sendMessage = (req, res) => {
  const { groupId } = req.params;
  const userId = req.user.userId;
  const { message, message_type = 'text' } = req.body;

  if (!message || !message.trim()) {
    return res.status(400).json({ error: 'Message cannot be empty' });
  }

  db.query(
    'SELECT 1 FROM group_booking_members WHERE group_booking_id = ? AND user_id = ? LIMIT 1',
    [groupId, userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (!rows || rows.length === 0) return res.status(403).json({ error: 'Not a member of this group' });

      db.query(
        'INSERT INTO group_chat_messages (group_booking_id, user_id, message, message_type) VALUES (?, ?, ?, ?)',
        [groupId, userId, message.trim(), message_type],
        (err2, result) => {
          if (err2) return res.status(500).json({ error: 'Database error' });

          const messageId = result.insertId;

          db.query(
            `SELECT gcm.message_id, gcm.group_booking_id, gcm.user_id,
                    gcm.message, gcm.message_type, gcm.created_at,
                    u.full_name AS sender_name, u.profile_picture_url AS sender_avatar
             FROM group_chat_messages gcm
             JOIN users u ON gcm.user_id = u.user_id
             WHERE gcm.message_id = ?`,
            [messageId],
            (err3, rows3) => {
              if (err3 || !rows3 || rows3.length === 0) {
                return res.status(201).json({ success: true, message_id: messageId });
              }

              const fullMessage = rows3[0];

              if (global.io) {
                global.io
                  .to(`group:${groupId}`)
                  .emit('chat:message', fullMessage);
              }

              res.status(201).json({ success: true, message: fullMessage });
            }
          );
        }
      );
    }
  );
};

const deleteMessage = (req, res) => {
  const { groupId, messageId } = req.params;
  const userId = req.user.userId;

  db.query(
    'DELETE FROM group_chat_messages WHERE message_id = ? AND group_booking_id = ? AND user_id = ?',
    [messageId, groupId, userId],
    (err, result) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (result.affectedRows === 0) return res.status(404).json({ error: 'Message not found or not yours' });

      if (global.io) {
        global.io.to(`group:${groupId}`).emit('chat:deleted', { message_id: parseInt(messageId) });
      }

      res.json({ success: true, message: 'Message deleted' });
    }
  );
};

module.exports = { getMessages, sendMessage, deleteMessage };
