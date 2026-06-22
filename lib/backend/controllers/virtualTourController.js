const VT = require('../models/virtualTour');
const axios = require('axios');

const GROQ_URL   = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.3-70b-versatile';

// ─── Public ───────────────────────────────────────────────────────────────────

const listTours = async (req, res) => {
  try {
    const { destination_id } = req.query;
    const tours = await VT.getAllTours({ destinationId: destination_id });
    res.json({ success: true, tours });
  } catch (e) {
    console.error('[VT] listTours:', e);
    res.status(500).json({ error: 'Database error' });
  }
};

const getTour = async (req, res) => {
  try {
    const tour = await VT.getTourById(req.params.id);
    if (!tour) return res.status(404).json({ error: 'Tour not found' });
    res.json({ success: true, tour });
  } catch (e) {
    console.error('[VT] getTour:', e);
    res.status(500).json({ error: 'Database error' });
  }
};

const getTourForDestination = async (req, res) => {
  try {
    const tour = await VT.getTourByDestination(req.params.destinationId);
    if (!tour) return res.status(404).json({ error: 'No virtual tour for this destination' });
    res.json({ success: true, tour });
  } catch (e) {
    console.error('[VT] getTourForDestination:', e);
    res.status(500).json({ error: 'Database error' });
  }
};

// ─── AI Narration ─────────────────────────────────────────────────────────────

const generateNarration = async (req, res) => {
  try {
    const { scene_id, scene_name, tour_title, destination_name } = req.body;
    if (!scene_name) return res.status(400).json({ error: 'scene_name required' });

    // Return cached narration if available
    const VTModel = require('../models/virtualTour');
    const [[sceneRow]] = await require('../config/db').promise
      ? [await require('../config/db').promise().query('SELECT ai_narration FROM virtual_tour_scenes WHERE id = ?', [scene_id])]
      : [[null]];

    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) return res.status(503).json({ error: 'AI service not configured' });

    const prompt = [
      `You are a professional tour guide narrating a virtual 360° tour of Pakistan.`,
      `You are currently at: ${scene_name}`,
      tour_title       ? `As part of the "${tour_title}" tour.`         : '',
      destination_name ? `Destination: ${destination_name}.`            : '',
      `Provide a 3-4 sentence engaging narration. Include:`,
      `- What the visitor is seeing right now`,
      `- A key historical or natural fact`,
      `- A travel tip or interesting detail`,
      `Keep it warm, vivid, and under 80 words. Do not use bullet points.`,
    ].filter(Boolean).join(' ');

    const response = await axios.post(
      GROQ_URL,
      {
        model: GROQ_MODEL,
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 200,
        temperature: 0.75,
      },
      {
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        timeout: 15000,
      }
    );

    const narration = response.data.choices?.[0]?.message?.content?.trim()
      || 'Welcome to this incredible location. Take a moment to look around in every direction.';

    // Cache to DB (fire-and-forget)
    if (scene_id) VT.saveAiNarration(scene_id, narration).catch(() => {});

    res.json({ success: true, narration });
  } catch (e) {
    console.error('[VT] generateNarration:', e.response?.data || e.message);
    res.status(500).json({ error: 'Failed to generate narration' });
  }
};

// ─── Admin: Tours ─────────────────────────────────────────────────────────────

const adminListTours = async (req, res) => {
  try {
    const tours = await VT.getAllTours({ includeInactive: true });
    res.json({ success: true, tours });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

const adminCreateTour = async (req, res) => {
  try {
    const { destination_id, title, description, thumbnail_url } = req.body;
    if (!title) return res.status(400).json({ error: 'title is required' });
    const tour = await VT.createTour({ destinationId: destination_id, title, description, thumbnailUrl: thumbnail_url });
    res.status(201).json({ success: true, tour });
  } catch (e) {
    console.error('[VT] adminCreateTour:', e);
    res.status(500).json({ error: 'Database error' });
  }
};

const adminUpdateTour = async (req, res) => {
  try {
    const { destination_id, title, description, thumbnail_url, is_active } = req.body;
    const tour = await VT.updateTour(req.params.id, {
      destinationId: destination_id, title, description,
      thumbnailUrl: thumbnail_url, isActive: is_active,
    });
    res.json({ success: true, tour });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

const adminDeleteTour = async (req, res) => {
  try {
    await VT.deleteTour(req.params.id);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

// ─── Admin: Scenes ────────────────────────────────────────────────────────────

const adminAddScene = async (req, res) => {
  try {
    const { scene_name, panorama_url, description, thumbnail_url, scene_order } = req.body;
    if (!scene_name || !panorama_url) return res.status(400).json({ error: 'scene_name and panorama_url required' });
    const scene = await VT.addScene(req.params.tourId, {
      sceneName: scene_name, panoramaUrl: panorama_url,
      description, thumbnailUrl: thumbnail_url, sceneOrder: scene_order,
    });
    res.status(201).json({ success: true, scene });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

const adminUpdateScene = async (req, res) => {
  try {
    const { scene_name, panorama_url, description, thumbnail_url, scene_order, ai_narration } = req.body;
    const scene = await VT.updateScene(req.params.sceneId, {
      sceneName: scene_name, panoramaUrl: panorama_url,
      description, thumbnailUrl: thumbnail_url,
      sceneOrder: scene_order, aiNarration: ai_narration,
    });
    res.json({ success: true, scene });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

const adminDeleteScene = async (req, res) => {
  try {
    await VT.deleteScene(req.params.sceneId);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

// ─── Admin: Hotspots ──────────────────────────────────────────────────────────

const adminAddHotspot = async (req, res) => {
  try {
    const { type, target_scene_id, title, text, pitch, yaw } = req.body;
    if (!type || !['scene','info'].includes(type)) return res.status(400).json({ error: 'type must be scene or info' });
    const hs = await VT.addHotspot(req.params.sceneId, {
      type, targetSceneId: target_scene_id, title, text, pitch, yaw,
    });
    res.status(201).json({ success: true, hotspot: hs });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

const adminUpdateHotspot = async (req, res) => {
  try {
    const { type, target_scene_id, title, text, pitch, yaw } = req.body;
    const hs = await VT.updateHotspot(req.params.hotspotId, {
      type, targetSceneId: target_scene_id, title, text, pitch, yaw,
    });
    res.json({ success: true, hotspot: hs });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

const adminDeleteHotspot = async (req, res) => {
  try {
    await VT.deleteHotspot(req.params.hotspotId);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Database error' });
  }
};

module.exports = {
  listTours, getTour, getTourForDestination, generateNarration,
  adminListTours, adminCreateTour, adminUpdateTour, adminDeleteTour,
  adminAddScene, adminUpdateScene, adminDeleteScene,
  adminAddHotspot, adminUpdateHotspot, adminDeleteHotspot,
};
