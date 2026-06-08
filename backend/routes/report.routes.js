const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.get('/profit-loss', reportController.getProfitLossReport);
router.get('/inventory-summary', reportController.getInventorySummary);

module.exports = router;
