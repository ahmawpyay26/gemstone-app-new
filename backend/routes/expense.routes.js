const express = require('express');
const router = express.Router();
const expenseController = require('../controllers/expense.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.post('/', expenseController.createExpense);
router.get('/gemstone/:gemstoneId', expenseController.getGemstoneExpenses);

module.exports = router;
