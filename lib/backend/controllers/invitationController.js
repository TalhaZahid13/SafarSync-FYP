const db = require('../config/db');
const Invitation = require('../models/invitation');
const { sendGroupInvitationEmail, sendInvitationResponseEmail } = require('../services/emailService');

const createNotification = (userId, title, message, type, relatedData = {}) => {
  const query = `
    INSERT INTO notifications (user_id, title, message, type, action_url)
    VALUES (?, ?, ?, ?, ?)
  `;
  const actionUrl = relatedData.action_url || null;
  db.query(query, [userId, title, message, type, actionUrl], (err) => {
    if (err) console.error('[Notification] DB insert error:', err.message);
  });

  if (global.io) {
    global.io.to(`user:${userId}`).emit('notification:new', { title, message, type });
  }
};

// POST /api/invitations/send
const sendInvitation = (req, res) => {
  const { group_booking_id, receiver_email } = req.body;
  const sender_id = req.user.userId;

  if (!group_booking_id || !receiver_email) {
    return res.status(400).json({ error: 'group_booking_id and receiver_email are required' });
  }

  // Look up receiver by email
  Invitation.getUserByEmail(receiver_email, (err, receiver) => {
    if (err) {
      console.error('[Invitation] Receiver lookup error:', err);
      return res.status(500).json({ error: 'Database error' });
    }
    if (!receiver) {
      return res.status(404).json({ error: 'No SafarSync user found with that email' });
    }

    const receiver_id = receiver.user_id;

    if (receiver_id === sender_id) {
      return res.status(400).json({ error: 'Cannot invite yourself' });
    }

    // Check already a member
    Invitation.checkAlreadyMember(group_booking_id, receiver_id, (err, isMember) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (isMember) return res.status(400).json({ error: 'User is already a member of this group' });

      // Get group and sender info
      const infoQuery = `
        SELECT gb.trip_name, u.full_name as sender_name
        FROM group_bookings gb
        JOIN users u ON u.user_id = ?
        WHERE gb.group_booking_id = ?
      `;
      db.query(infoQuery, [sender_id, group_booking_id], (err, rows) => {
        if (err || !rows || rows.length === 0) {
          return res.status(404).json({ error: 'Group booking not found' });
        }

        const { trip_name, sender_name } = rows[0];

        // Create invitation record
        Invitation.create(group_booking_id, sender_id, receiver_id, (err, result) => {
          if (err) {
            if (err.code === 'ER_DUP_ENTRY') {
              return res.status(400).json({ error: 'Invitation already sent to this user' });
            }
            console.error('[Invitation] Create error:', err);
            return res.status(500).json({ error: 'Failed to send invitation' });
          }

          const invitationId = result.insertId;
          const message = `You have been invited to join "${trip_name}" by ${sender_name}.`;

          // In-app notification
          createNotification(
            receiver_id,
            'Group Booking Invitation',
            message,
            'group_invitation',
            { action_url: `/invitations/${invitationId}` }
          );

          // Email (async — don't block response)
          sendGroupInvitationEmail({
            toEmail: receiver.email,
            toName: receiver.full_name,
            senderName: sender_name,
            tripName: trip_name,
            invitationId,
          });

          res.status(201).json({
            success: true,
            invitation_id: invitationId,
            message: `Invitation sent to ${receiver.email}`,
          });
        });
      });
    });
  });
};

// PUT /api/invitations/:id/respond
const respondToInvitation = (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const receiver_id = req.user.userId;

  if (!['Accepted', 'Declined'].includes(status)) {
    return res.status(400).json({ error: 'status must be Accepted or Declined' });
  }

  Invitation.findById(id, (err, invitation) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found' });
    if (invitation.status !== 'Pending') {
      return res.status(400).json({ error: `Invitation already ${invitation.status}` });
    }

    Invitation.updateStatus(id, receiver_id, status, (err, result) => {
      if (err) return res.status(500).json({ error: 'Failed to update invitation' });
      if (result.affectedRows === 0) {
        return res.status(403).json({ error: 'Not authorized to respond to this invitation' });
      }

      if (status === 'Accepted') {
        // Add to group members
        const addMemberQuery = `
          INSERT IGNORE INTO group_booking_members (group_booking_id, user_id)
          VALUES (?, ?)
        `;
        db.query(addMemberQuery, [invitation.group_booking_id, receiver_id], (err) => {
          if (err) console.error('[Invitation] Add member error:', err.message);
        });

        // Notify sender
        createNotification(
          invitation.sender_id,
          'Invitation Accepted',
          `${invitation.receiver_name} has accepted your invitation to join "${invitation.trip_name}".`,
          'invitation_accepted'
        );

        // Emit to group tracking room so map updates
        if (global.io) {
          global.io.to(`group-tracking:${invitation.group_booking_id}`).emit('member:joined', {
            group_booking_id: invitation.group_booking_id,
            user_id: receiver_id,
            user_name: invitation.receiver_name,
          });
        }

        // Email organizer
        sendInvitationResponseEmail({
          toEmail: invitation.sender_email,
          toName: invitation.sender_name,
          responderName: invitation.receiver_name,
          tripName: invitation.trip_name,
          status: 'Accepted',
        });
      } else {
        // Notify sender of decline
        createNotification(
          invitation.sender_id,
          'Invitation Declined',
          `${invitation.receiver_name} has declined the invitation to "${invitation.trip_name}".`,
          'invitation_declined'
        );

        sendInvitationResponseEmail({
          toEmail: invitation.sender_email,
          toName: invitation.sender_name,
          responderName: invitation.receiver_name,
          tripName: invitation.trip_name,
          status: 'Declined',
        });
      }

      res.json({ success: true, status, message: `Invitation ${status}` });
    });
  });
};

// GET /api/invitations/received
const getReceivedInvitations = (req, res) => {
  const receiver_id = req.user.userId;

  Invitation.findByReceiver(receiver_id, (err, invitations) => {
    if (err) {
      console.error('[Invitation] Fetch received error:', err);
      return res.status(500).json({ error: 'Failed to fetch invitations' });
    }
    res.json({ success: true, invitations: invitations || [] });
  });
};

// GET /api/invitations/sent
const getSentInvitations = (req, res) => {
  const sender_id = req.user.userId;

  Invitation.findBySender(sender_id, (err, invitations) => {
    if (err) {
      console.error('[Invitation] Fetch sent error:', err);
      return res.status(500).json({ error: 'Failed to fetch invitations' });
    }
    res.json({ success: true, invitations: invitations || [] });
  });
};

// GET /api/invitations/pending-count
const getPendingCount = (req, res) => {
  const receiver_id = req.user.userId;

  Invitation.getPendingCount(receiver_id, (err, count) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json({ success: true, pending_count: count });
  });
};

module.exports = {
  sendInvitation,
  respondToInvitation,
  getReceivedInvitations,
  getSentInvitations,
  getPendingCount,
};
