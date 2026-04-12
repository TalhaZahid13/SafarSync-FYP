const db = require('../config/db');

// Send message to AI
const sendMessage = (req, res) => {
  const user_id = req.user.userId;
  const { message, context_data } = req.body;

  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }

  // TODO: Integrate with AI service (OpenAI, Google AI, etc.)
  const aiResponse = generateAIResponse(message);

  const query = `INSERT INTO ai_chat_history 
    (user_id, user_message, ai_response, context_data)
    VALUES (?, ?, ?, ?)`;

  db.query(query, [user_id, message, aiResponse, JSON.stringify(context_data || {})], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to save message' });
    }

    res.json({
      chat_id: results.insertId,
      user_message: message,
      ai_response: aiResponse,
    });
  });
};

// Get AI recommendations
const getRecommendations = (req, res) => {
  const user_id = req.user.userId;
  const { limit = 10 } = req.query;

  const query = `SELECT ar.*, d.* FROM ai_recommendations ar
    JOIN destinations d ON ar.destination_id = d.destination_id
    WHERE ar.user_id = ? AND ar.viewed = FALSE
    ORDER BY ar.confidence_score DESC
    LIMIT ?`;

  db.query(query, [user_id, parseInt(limit)], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to fetch recommendations' });
    }
    res.json({ recommendations: results });
  });
};

// Get chat history
const getChatHistory = (req, res) => {
  const user_id = req.user.userId;
  const { limit = 50 } = req.query;

  const query = `SELECT * FROM ai_chat_history 
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT ?`;

  db.query(query, [user_id, parseInt(limit)], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to fetch chat history' });
    }
    res.json({ chatHistory: results.reverse() });
  });
};

// Clear chat history
const clearChatHistory = (req, res) => {
  const user_id = req.user.userId;

  const query = 'DELETE FROM ai_chat_history WHERE user_id = ?';

  db.query(query, [user_id], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to clear chat history' });
    }
    res.json({ message: 'Chat history cleared' });
  });
};

// Rate recommendation
const rateRecommendation = (req, res) => {
  const { id } = req.params;
  const user_id = req.user.userId;
  const { helpful } = req.body;

  const query = `UPDATE ai_recommendations 
    SET viewed = TRUE, helpful_rating = ?
    WHERE recommendation_id = ? AND user_id = ?`;

  db.query(query, [helpful ? 1 : 0, id, user_id], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to rate recommendation' });
    }
    res.json({ message: 'Recommendation rated' });
  });
};

// Mock AI response generator
function generateAIResponse(userMessage) {
  const responses = [
    'That sounds like an amazing travel plan! Would you like me to suggest some nearby attractions?',
    'I think visiting during the off-season would give you a better experience. Shall I check the weather forecast?',
    'Based on your interests, I recommend exploring local cuisine and cultural sites in this area.',
    'This destination has excellent reviews. Would you like to add it to your wishlist?',
    'I can help you plan the best route considering weather and traffic conditions.',
  ];

  return responses[Math.floor(Math.random() * responses.length)];
}

module.exports = {
  sendMessage,
  getRecommendations,
  getChatHistory,
  clearChatHistory,
  rateRecommendation,
};
