const db = require('../config/db');

const TourPackage = {
  getAll: ({ category, maxPrice, maxDays, search } = {}) => {
    let sql = 'SELECT * FROM tour_packages WHERE is_active = 1';
    const params = [];
    if (category && category !== 'all') {
      sql += ' AND category = ?'; params.push(category);
    }
    if (maxPrice) {
      sql += ' AND total_price <= ?'; params.push(maxPrice);
    }
    if (maxDays) {
      sql += ' AND duration_days <= ?'; params.push(maxDays);
    }
    if (search) {
      sql += ' AND (title LIKE ? OR description LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }
    sql += ' ORDER BY total_price ASC';
    return db.promise().query(sql, params);
  },

  getById: (id) =>
    db.promise().query('SELECT * FROM tour_packages WHERE package_id = ? AND is_active = 1', [id]),

  create: (data) =>
    db.promise().query(
      `INSERT INTO tour_packages
         (title, description, duration_days, total_price, category,
          destinations, itinerary, includes, image_url, is_ai_generated, created_by_admin)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        data.title, data.description, data.duration_days, data.total_price,
        data.category || 'General',
        JSON.stringify(data.destinations || []),
        JSON.stringify(data.itinerary || []),
        JSON.stringify(data.includes || []),
        data.image_url || null,
        data.is_ai_generated ? 1 : 0,
        data.created_by_admin || null,
      ]
    ),

  update: (id, data) =>
    db.promise().query(
      `UPDATE tour_packages SET
         title=?, description=?, duration_days=?, total_price=?,
         category=?, destinations=?, itinerary=?, includes=?, image_url=?, updated_at=NOW()
       WHERE package_id=?`,
      [
        data.title, data.description, data.duration_days, data.total_price,
        data.category, JSON.stringify(data.destinations || []),
        JSON.stringify(data.itinerary || []), JSON.stringify(data.includes || []),
        data.image_url || null, id,
      ]
    ),

  deactivate: (id) =>
    db.promise().query('UPDATE tour_packages SET is_active=0, updated_at=NOW() WHERE package_id=?', [id]),

  saveBudgetPlan: (userId, budget, travelers, days, city, prefs, plan) =>
    db.promise().query(
      `INSERT INTO budget_plans
         (user_id, budget_amount, num_travelers, duration_days, start_city, preferences, generated_plan)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [userId, budget, travelers, days, city || null, prefs || null, JSON.stringify(plan)]
    ),

  getUserBudgetPlans: (userId) =>
    db.promise().query(
      'SELECT * FROM budget_plans WHERE user_id=? ORDER BY created_at DESC LIMIT 10',
      [userId]
    ),
};

module.exports = TourPackage;
