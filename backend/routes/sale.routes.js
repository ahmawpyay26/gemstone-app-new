const express = require('express');
const router = express.Router();
const saleController = require('../controllers/sale.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.post('/', saleController.createSale);
router.get('/', saleController.getAllSales);

module.exports = router;
