const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const destinationController = require('../controllers/destinationController');

// Get all destinations with filters
router.get('/', destinationController.getAllDestinations);

// Search destinations
router.get('/search', destinationController.searchDestinations);

// Get destination by ID
router.get('/:id', destinationController.getDestinationById);

// Create destination (admin only)
router.post('/', authenticate, destinationController.createDestination);

// Update destination (admin only)
router.put('/:id', authenticate, destinationController.updateDestination);

// Delete destination (admin only)
router.delete('/:id', authenticate, destinationController.deleteDestination);

// Get destinations by category
router.get('/category/:category', destinationController.getDestinationsByCategory);

// Get popular destinations
router.get('/popular/trending', destinationController.getPopularDestinations);

module.exports = router;
