const express = require('express');
const router = express.Router();
const { authenticate: authenticateToken } = require('../middleware/authMiddleware');
const ctrl = require('../controllers/virtualTourController');

// Public
router.get('/',                           ctrl.listTours);
router.get('/destination/:destinationId', ctrl.getTourForDestination);
router.get('/:id',                        ctrl.getTour);
router.post('/narration',                 authenticateToken, ctrl.generateNarration);

module.exports = router;
