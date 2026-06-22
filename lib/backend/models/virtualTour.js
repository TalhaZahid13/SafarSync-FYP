const db = require('../config/db');

// ─── Helpers ──────────────────────────────────────────────────────────────────

const q = (sql, params) =>
  new Promise((resolve, reject) =>
    db.query(sql, params, (err, rows) => (err ? reject(err) : resolve(rows)))
  );

// ─── Read ─────────────────────────────────────────────────────────────────────

const getAllTours = async ({ includeInactive = false, destinationId } = {}) => {
  let sql = `
    SELECT vt.*, d.name AS destination_name
    FROM virtual_tours vt
    LEFT JOIN destination d ON d.destinationId = vt.destination_id
    WHERE 1=1
  `;
  const params = [];
  if (!includeInactive) { sql += ' AND vt.is_active = 1'; }
  if (destinationId)    { sql += ' AND vt.destination_id = ?'; params.push(destinationId); }
  sql += ' ORDER BY vt.created_at DESC';
  return q(sql, params);
};

const getTourById = async (id) => {
  const [tour] = await q(
    `SELECT vt.*, d.name AS destination_name
     FROM virtual_tours vt
     LEFT JOIN destination d ON d.destinationId = vt.destination_id
     WHERE vt.id = ?`,
    [id]
  );
  if (!tour) return null;

  const scenes = await q(
    'SELECT * FROM virtual_tour_scenes WHERE tour_id = ? ORDER BY scene_order ASC',
    [id]
  );

  const sceneIds = scenes.map((s) => s.id);
  const hotspots =
    sceneIds.length > 0
      ? await q(
          `SELECT h.*, ts.id AS target_scene_db_id
           FROM virtual_tour_hotspots h
           LEFT JOIN virtual_tour_scenes ts ON ts.id = h.target_scene_id
           WHERE h.scene_id IN (?)`,
          [sceneIds]
        )
      : [];

  tour.scenes = scenes.map((scene) => ({
    ...scene,
    sceneKey: `scene_${scene.id}`,
    hotspots: hotspots
      .filter((h) => h.scene_id === scene.id)
      .map((h) => ({
        ...h,
        targetSceneKey: h.target_scene_id ? `scene_${h.target_scene_id}` : null,
      })),
  }));

  tour.defaultSceneKey = tour.scenes.length > 0 ? tour.scenes[0].sceneKey : null;

  return tour;
};

const getTourByDestination = async (destinationId) => {
  const [row] = await q(
    'SELECT id FROM virtual_tours WHERE destination_id = ? AND is_active = 1 LIMIT 1',
    [destinationId]
  );
  if (!row) return null;
  return getTourById(row.id);
};

// ─── Create / Update / Delete ─────────────────────────────────────────────────

const createTour = async ({ destinationId, title, description, thumbnailUrl }) => {
  const result = await q(
    'INSERT INTO virtual_tours (destination_id, title, description, thumbnail_url) VALUES (?,?,?,?)',
    [destinationId || null, title, description || null, thumbnailUrl || null]
  );
  return getTourById(result.insertId);
};

const updateTour = async (id, { destinationId, title, description, thumbnailUrl, isActive }) => {
  await q(
    `UPDATE virtual_tours
     SET destination_id = ?, title = ?, description = ?, thumbnail_url = ?, is_active = ?
     WHERE id = ?`,
    [destinationId || null, title, description || null, thumbnailUrl || null,
     isActive !== undefined ? isActive : 1, id]
  );
  return getTourById(id);
};

const deleteTour = async (id) => {
  await q('DELETE FROM virtual_tours WHERE id = ?', [id]);
};

// ─── Scenes ───────────────────────────────────────────────────────────────────

const addScene = async (tourId, { sceneName, panoramaUrl, description, thumbnailUrl, sceneOrder }) => {
  const result = await q(
    `INSERT INTO virtual_tour_scenes (tour_id, scene_name, panorama_url, description, thumbnail_url, scene_order)
     VALUES (?,?,?,?,?,?)`,
    [tourId, sceneName, panoramaUrl, description || null, thumbnailUrl || null, sceneOrder ?? 0]
  );
  const [scene] = await q('SELECT * FROM virtual_tour_scenes WHERE id = ?', [result.insertId]);
  return scene;
};

const updateScene = async (id, { sceneName, panoramaUrl, description, thumbnailUrl, sceneOrder, aiNarration }) => {
  await q(
    `UPDATE virtual_tour_scenes
     SET scene_name=?, panorama_url=?, description=?, thumbnail_url=?, scene_order=?, ai_narration=?
     WHERE id = ?`,
    [sceneName, panoramaUrl, description || null, thumbnailUrl || null,
     sceneOrder ?? 0, aiNarration || null, id]
  );
  const [scene] = await q('SELECT * FROM virtual_tour_scenes WHERE id = ?', [id]);
  return scene;
};

const deleteScene = async (id) => {
  await q('DELETE FROM virtual_tour_scenes WHERE id = ?', [id]);
};

const saveAiNarration = async (sceneId, narration) => {
  await q('UPDATE virtual_tour_scenes SET ai_narration = ? WHERE id = ?', [narration, sceneId]);
};

// ─── Hotspots ─────────────────────────────────────────────────────────────────

const addHotspot = async (sceneId, { type, targetSceneId, title, text, pitch, yaw }) => {
  const result = await q(
    `INSERT INTO virtual_tour_hotspots (scene_id, type, target_scene_id, title, text, pitch, yaw)
     VALUES (?,?,?,?,?,?,?)`,
    [sceneId, type, targetSceneId || null, title || null, text || null, pitch ?? 0, yaw ?? 0]
  );
  const [hs] = await q('SELECT * FROM virtual_tour_hotspots WHERE id = ?', [result.insertId]);
  return hs;
};

const updateHotspot = async (id, { type, targetSceneId, title, text, pitch, yaw }) => {
  await q(
    `UPDATE virtual_tour_hotspots
     SET type=?, target_scene_id=?, title=?, text=?, pitch=?, yaw=? WHERE id=?`,
    [type, targetSceneId || null, title || null, text || null, pitch ?? 0, yaw ?? 0, id]
  );
  const [hs] = await q('SELECT * FROM virtual_tour_hotspots WHERE id = ?', [id]);
  return hs;
};

const deleteHotspot = async (id) => {
  await q('DELETE FROM virtual_tour_hotspots WHERE id = ?', [id]);
};

module.exports = {
  getAllTours, getTourById, getTourByDestination,
  createTour, updateTour, deleteTour,
  addScene, updateScene, deleteScene, saveAiNarration,
  addHotspot, updateHotspot, deleteHotspot,
};
