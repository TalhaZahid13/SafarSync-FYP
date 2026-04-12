const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const routeController = require('../controllers/routeController');

// Create new route
router.post('/', authenticate, routeController.createRoute);

// Get user's routes
router.get('/', authenticate, routeController.getUserRoutes);

// Get route by ID
router.get('/:id', routeController.getRouteById);

// Update route
router.put('/:id', authenticate, routeController.updateRoute);

// Delete route
router.delete('/:id', authenticate, routeController.deleteRoute);

// Optimize route (weather/traffic)
router.post('/:id/optimize', authenticate, routeController.optimizeRoute);

// Add stop to route
router.post('/:id/stops', authenticate, routeController.addRouteStop);

// Get public routes
router.get('/public/trending', routeController.getPublicRoutes);

module.exports = router;
