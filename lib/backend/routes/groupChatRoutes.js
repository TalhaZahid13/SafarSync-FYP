const express = require('express');
const { authenticate } = require('../middleware/authMiddleware');
const { getMessages, sendMessage, deleteMessage } = require('../controllers/groupChatController');

const router = express.Router();

router.get('/:groupId/messages',              authenticate, getMessages);
router.post('/:groupId/messages',             authenticate, sendMessage);
router.delete('/:groupId/messages/:messageId', authenticate, deleteMessage);

module.exports = router;
