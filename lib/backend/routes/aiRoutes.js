const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const aiController = require('../controllers/aiController');

// Send message to AI
router.post('/chat', authenticate, aiController.sendMessage);

// Get AI recommendations
router.get('/recommendations', authenticate, aiController.getRecommendations);

// Get chat history
router.get('/history', authenticate, aiController.getChatHistory);

// Clear chat history
router.delete('/history', authenticate, aiController.clearChatHistory);

// Rate recommendation
router.post('/recommendations/:id/rate', authenticate, aiController.rateRecommendation);

module.exports = router;
