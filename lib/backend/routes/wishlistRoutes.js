const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const wishlistController = require('../controllers/wishlistController');

// Get user's wishlist
router.get('/', authenticate, wishlistController.getWishlist);

// Add to wishlist
router.post('/', authenticate, wishlistController.addToWishlist);

// Remove from wishlist
router.delete('/:destinationId', authenticate, wishlistController.removeFromWishlist);

// Check if destination is in wishlist
router.get('/check/:destinationId', authenticate, wishlistController.checkInWishlist);

// Update wishlist item
router.put('/:destinationId', authenticate, wishlistController.updateWishlistItem);

module.exports = router;
