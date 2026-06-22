const axios = require('axios');
const db = require('../config/db');

const GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.3-70b-versatile';

const SYSTEM_PROMPT = `You are Safar AI, a travel assistant specializing in Pakistan tourism.
You help travelers plan trips, discover destinations, understand local culture, find food spots,
and stay safe while traveling in Pakistan. You are friendly, concise, and always give practical advice.
When asked about other topics, gently redirect to travel-related assistance.`;

const WELLNESS_SYSTEM_PROMPT = `You are SafarSync's wellness companion for travelers.
You help with travel anxiety, jet lag, culture shock, loneliness on trips, and maintaining
mental and physical health while traveling. Be empathetic, supportive, and give actionable tips.
Keep responses warm, brief, and practical.`;
async function callGroq(messages, systemPrompt) {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error('GROQ_API_KEY not configured');

  const response = await axios.post(
    GROQ_API_URL,
    {
      model: GROQ_MODEL,
      messages: [{ role: 'system', content: systemPrompt }, ...messages],
      max_tokens: 512,
      temperature: 0.7,
    },
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      timeout: 15000,
    }
  );

  return response.data.choices?.[0]?.message?.content || 'I could not generate a response. Please try again.';
}

const sendMessage = async (req, res) => {
  const userId = req.user.userId;
  const { message, context_data, history = [] } = req.body;

  if (!message) return res.status(400).json({ error: 'Message is required' });

  const messages = [
    ...history.slice(-10).map((h) => [
      { role: 'user', content: h.user_message },
      { role: 'assistant', content: h.ai_response },
    ]).flat(),
    { role: 'user', content: message },
  ];

  let aiResponse;
  try {
    aiResponse = await callGroq(messages, SYSTEM_PROMPT);
  } catch (err) {
    console.error('[AI] Groq API error:', err.message);
    return res.status(502).json({ error: 'AI service unavailable. Please try again later.' });
  }

  const query = `INSERT INTO ai_chat_history (user_id, user_message, ai_response, context_data) VALUES (?, ?, ?, ?)`;
  db.query(query, [userId, message, aiResponse, JSON.stringify(context_data || {})], (err, result) => {
    if (err) console.error('[AI] Failed to save chat:', err.message);
    res.json({
      chat_id: result?.insertId || null,
      user_message: message,
      ai_response: aiResponse,
    });
  });
};

const wellnessChat = async (req, res) => {
  const userId = req.user.userId;
  const { message, history = [] } = req.body;

  if (!message) return res.status(400).json({ error: 'Message is required' });

  const messages = [
    ...history.slice(-6).map((h) => [
      { role: 'user', content: h.user_message },
      { role: 'assistant', content: h.ai_response },
    ]).flat(),
    { role: 'user', content: message },
  ];

  let aiResponse;
  try {
    aiResponse = await callGroq(messages, WELLNESS_SYSTEM_PROMPT);
  } catch (err) {
    console.error('[AI] Wellness Groq error:', err.message);
    return res.status(502).json({ error: 'AI service unavailable. Please try again later.' });
  }

  db.query(
    'INSERT INTO ai_chat_history (user_id, user_message, ai_response, context_data) VALUES (?, ?, ?, ?)',
    [userId, message, aiResponse, JSON.stringify({ type: 'wellness' })],
    (err) => { if (err) console.error('[AI] Wellness save error:', err.message); }
  );

  res.json({ user_message: message, ai_response: aiResponse });
};

const getRecommendations = (req, res) => {
  const userId = req.user.userId;
  const limit = parseInt(req.query.limit) || 10;

  db.query(
    `SELECT ar.*, d.name, d.city, d.country, d.description, d.image_url, d.rating
     FROM ai_recommendations ar
     JOIN destinations d ON ar.destination_id = d.destination_id
     WHERE ar.user_id = ? AND ar.viewed = FALSE
     ORDER BY ar.confidence_score DESC LIMIT ?`,
    [userId, limit],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      res.json({ recommendations: rows || [] });
    }
  );
};

const getChatHistory = (req, res) => {
  const userId = req.user.userId;
  const limit = parseInt(req.query.limit) || 50;

  db.query(
    'SELECT * FROM ai_chat_history WHERE user_id = ? ORDER BY created_at DESC LIMIT ?',
    [userId, limit],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      res.json({ chatHistory: (rows || []).reverse() });
    }
  );
};

const clearChatHistory = (req, res) => {
  const userId = req.user.userId;
  db.query('DELETE FROM ai_chat_history WHERE user_id = ?', [userId], (err) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json({ message: 'Chat history cleared' });
  });
};

const rateRecommendation = (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;
  const { helpful } = req.body;

  db.query(
    'UPDATE ai_recommendations SET viewed = TRUE, helpful_rating = ? WHERE recommendation_id = ? AND user_id = ?',
    [helpful ? 1 : 0, id, userId],
    (err) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      res.json({ message: 'Recommendation rated' });
    }
  );
};

module.exports = { sendMessage, wellnessChat, getRecommendations, getChatHistory, clearChatHistory, rateRecommendation };
