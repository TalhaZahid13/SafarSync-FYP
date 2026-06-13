const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  sendInvitation,
  respondToInvitation,
  getReceivedInvitations,
  getSentInvitations,
  getPendingCount,
} = require('../controllers/invitationController');

router.post('/send', authenticate, sendInvitation);
router.get('/received', authenticate, getReceivedInvitations);
router.get('/sent', authenticate, getSentInvitations);
router.get('/pending-count', authenticate, getPendingCount);
router.put('/:id/respond', authenticate, respondToInvitation);

module.exports = router;
