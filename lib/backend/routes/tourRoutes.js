const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/authMiddleware');
const { listPackages, getPackage, generateBudgetPlan, getBudgetHistory } = require('../controllers/tourController');

// Public: browse packages
router.get('/packages',        listPackages);
router.get('/packages/:id',    getPackage);

// Authenticated: budget planner
router.post('/budget-plan',    authenticateToken, generateBudgetPlan);
router.get('/budget-history',  authenticateToken, getBudgetHistory);

module.exports = router;
