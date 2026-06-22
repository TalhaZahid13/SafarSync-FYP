const TourPackage = require('../models/tourPackage');
const db = require('../config/db');
const axios = require('axios');

const GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.3-70b-versatile';

// ─── GET /api/tours/packages ─────────────────────────────────────────────────
const listPackages = async (req, res) => {
  try {
    const { category, max_price, max_days, search } = req.query;
    const [rows] = await TourPackage.getAll({
      category,
      maxPrice: max_price ? parseFloat(max_price) : null,
      maxDays: max_days ? parseInt(max_days) : null,
      search,
    });
    // Parse JSON fields
    const packages = rows.map(_parsePackage);
    res.json({ success: true, packages });
  } catch (err) {
    console.error('listPackages error:', err);
    res.status(500).json({ error: 'Failed to load packages' });
  }
};

// ─── GET /api/tours/packages/:id ─────────────────────────────────────────────
const getPackage = async (req, res) => {
  try {
    const [rows] = await TourPackage.getById(req.params.id);
    if (!rows.length) return res.status(404).json({ error: 'Package not found' });
    res.json({ success: true, package: _parsePackage(rows[0]) });
  } catch (err) {
    console.error('getPackage error:', err);
    res.status(500).json({ error: 'Failed to load package' });
  }
};

// ─── POST /api/tours/budget-plan ─────────────────────────────────────────────
// AI-powered budget planner: generate a complete itinerary within a budget
const generateBudgetPlan = async (req, res) => {
  const userId = req.user.userId;
  const { budget_amount, num_travelers, duration_days, start_city, preferences } = req.body;

  if (!budget_amount || !duration_days) {
    return res.status(400).json({ error: 'budget_amount and duration_days are required' });
  }

  const budget = parseFloat(budget_amount);
  const travelers = parseInt(num_travelers) || 1;
  const days = parseInt(duration_days);
  const perPersonBudget = Math.round(budget / travelers);

  try {
    // 1. Fetch matching packages from DB first
    const [pkgRows] = await TourPackage.getAll({ maxPrice: budget, maxDays: days });
    const matchingPackages = pkgRows.slice(0, 3).map(_parsePackage);

    // 2. Fetch affordable destinations
    const [destRows] = await db.promise().query(
      `SELECT destination_id, name, city, country, category, average_cost, description
       FROM destinations
       WHERE average_cost IS NOT NULL AND average_cost <= ?
       ORDER BY rating DESC LIMIT 8`,
      [perPersonBudget * days]
    );

    // 3. Build AI prompt
    const prompt = `You are a Pakistan travel expert. Generate a detailed budget travel plan with this exact JSON structure.

User requirements:
- Total budget: PKR ${budget} for ${travelers} traveler(s)
- Per person budget: PKR ${perPersonBudget}
- Duration: ${days} days
- Start city: ${start_city || 'any city in Pakistan'}
- Preferences: ${preferences || 'nature, adventure, culture'}

Available affordable destinations: ${destRows.map(d => `${d.name} (${d.city}, avg cost PKR ${d.average_cost}/day)`).join(', ')}

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{
  "title": "Trip name",
  "total_estimated_cost": 0,
  "daily_budget": 0,
  "recommended_destinations": ["dest1", "dest2"],
  "itinerary": [
    {"day": 1, "location": "City", "activities": ["Activity 1", "Activity 2"], "estimated_cost": 0, "transport": "How to get there", "accommodation": "Where to stay"}
  ],
  "money_saving_tips": ["tip1", "tip2", "tip3"],
  "best_time_to_go": "Month/Season",
  "included_in_budget": ["item1", "item2"],
  "not_included": ["item1"]
}`;

    let aiPlan = null;
    try {
      const apiKey = process.env.GROQ_API_KEY;
      if (apiKey) {
        const resp = await axios.post(
          GROQ_API_URL,
          {
            model: GROQ_MODEL,
            messages: [{ role: 'user', content: prompt }],
            max_tokens: 1000,
            temperature: 0.6,
          },
          { headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' }, timeout: 20000 }
        );
        const raw = resp.data.choices?.[0]?.message?.content || '';
        // Extract JSON from response
        const jsonMatch = raw.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          aiPlan = JSON.parse(jsonMatch[0]);
        }
      }
    } catch (aiErr) {
      console.error('AI plan generation error (non-fatal):', aiErr.message);
    }

    // Fallback plan if AI fails
    if (!aiPlan) {
      aiPlan = _generateFallbackPlan(budget, travelers, days, start_city, destRows);
    }

    // 4. Save to DB
    await TourPackage.saveBudgetPlan(userId, budget, travelers, days, start_city, preferences, aiPlan).catch(() => {});

    res.json({
      success: true,
      budget_plan: aiPlan,
      matching_packages: matchingPackages,
      affordable_destinations: destRows.slice(0, 6),
    });
  } catch (err) {
    console.error('generateBudgetPlan error:', err);
    res.status(500).json({ error: 'Failed to generate budget plan' });
  }
};

// ─── GET /api/tours/budget-history ───────────────────────────────────────────
const getBudgetHistory = async (req, res) => {
  try {
    const [rows] = await TourPackage.getUserBudgetPlans(req.user.userId);
    res.json({ success: true, plans: rows.map(r => ({ ...r, generated_plan: _safeJson(r.generated_plan) })) });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch history' });
  }
};

// ─── Helpers ──────────────────────────────────────────────────────────────────
function _parsePackage(row) {
  return {
    ...row,
    destinations: _safeJson(row.destinations) || [],
    itinerary: _safeJson(row.itinerary) || [],
    includes: _safeJson(row.includes) || [],
  };
}

function _safeJson(val) {
  if (typeof val === 'object') return val;
  try { return JSON.parse(val); } catch (_) { return null; }
}

function _generateFallbackPlan(budget, travelers, days, startCity, destinations) {
  const perDay = Math.round(budget / travelers / days);
  const dests = destinations.slice(0, Math.min(days, 3)).map(d => d.name);
  return {
    title: `${days}-Day Budget Adventure in Pakistan`,
    total_estimated_cost: budget,
    daily_budget: perDay * travelers,
    recommended_destinations: dests.length ? dests : ['Murree', 'Naran', 'Swat'],
    itinerary: Array.from({ length: days }, (_, i) => ({
      day: i + 1,
      location: dests[i % dests.length] || 'Islamabad',
      activities: ['Explore local attractions', 'Try local food', 'Sightseeing'],
      estimated_cost: perDay * travelers,
      transport: 'Public bus / Coaster (most affordable)',
      accommodation: 'Local guesthouse or budget hotel',
    })),
    money_saving_tips: [
      'Travel by public transport (Coasters/buses) instead of renting cars',
      'Stay in guesthouses rather than hotels — often cleaner and cheaper',
      'Eat at local dhabas for authentic food at 1/5 the restaurant price',
      'Book accommodations in advance for better rates',
      'Travel off-season (Oct–Mar for northern areas) for discounts',
    ],
    best_time_to_go: 'April–October for northern areas, October–March for south',
    included_in_budget: ['Accommodation', 'Transport', 'Main meals', 'Entry tickets'],
    not_included: ['Flights', 'Personal shopping', 'Tips', 'Emergency expenses'],
  };
}

module.exports = { listPackages, getPackage, generateBudgetPlan, getBudgetHistory };
