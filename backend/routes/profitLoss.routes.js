const express = require('express');
const router = express.Router();
const { authenticateToken, authorizeRole } = require('../middleware/auth.middleware');
const ProfitLossService = require('../services/profitLoss.service');
const LotPurchaseService = require('../services/lotPurchase.service');
const ExpenseAllocationService = require('../services/expenseAllocation.service');

// Create sale
router.post('/sales', authenticateToken, async (req, res) => {
  try {
    const { error, value } = validateSaleData(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const sale = await ProfitLossService.createSale({
      ...value,
      createdBy: req.user.id
    });

    res.status(201).json(sale);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add item to sale
router.post('/sales/:saleId/items', authenticateToken, async (req, res) => {
  try {
    const item = await ProfitLossService.addSaleItem(req.params.saleId, req.body);
    res.status(201).json(item);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get sale profit
router.get('/sales/:saleId/profit', authenticateToken, async (req, res) => {
  try {
    const profit = await ProfitLossService.calculateSaleProfit(req.params.saleId);
    if (!profit) {
      return res.status(404).json({ error: 'Sale not found' });
    }
    res.json(profit);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get stone profit
router.get('/stones/:gemstoneId/profit', authenticateToken, async (req, res) => {
  try {
    const profit = await ProfitLossService.calculateStoneProfit(req.params.gemstoneId);
    if (!profit) {
      return res.status(404).json({ error: 'Stone not found or not sold' });
    }
    res.json(profit);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get lot profit
router.get('/lots/:lotId/profit', authenticateToken, async (req, res) => {
  try {
    const profit = await ProfitLossService.calculateLotProfit(req.params.lotId);
    if (!profit) {
      return res.status(404).json({ error: 'Lot not found' });
    }
    res.json(profit);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get daily profit/loss
router.get('/daily-profit-loss', authenticateToken, async (req, res) => {
  try {
    const { date, branchId } = req.query;

    if (!date) {
      return res.status(400).json({ error: 'Date is required' });
    }

    const dailyPL = await ProfitLossService.calculateDailyProfitLoss(date, branchId);
    res.json(dailyPL);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get monthly profit/loss
router.get('/monthly-profit-loss', authenticateToken, async (req, res) => {
  try {
    const { yearMonth, branchId } = req.query;

    if (!yearMonth) {
      return res.status(400).json({ error: 'Year-month is required (YYYY-MM)' });
    }

    const monthlyPL = await ProfitLossService.calculateMonthlyProfitLoss(yearMonth, branchId);
    res.json(monthlyPL);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get branch profit
router.get('/branch-profit', authenticateToken, async (req, res) => {
  try {
    const { branchId, startDate, endDate } = req.query;

    if (!branchId || !startDate || !endDate) {
      return res.status(400).json({ error: 'branchId, startDate, and endDate are required' });
    }

    const branchProfit = await ProfitLossService.calculateBranchProfit(branchId, startDate, endDate);
    res.json(branchProfit);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Confirm sale
router.post('/sales/:saleId/confirm', authenticateToken, async (req, res) => {
  try {
    const result = await ProfitLossService.confirmSale(req.params.saleId);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Complete sale
router.post('/sales/:saleId/complete', authenticateToken, async (req, res) => {
  try {
    const result = await ProfitLossService.completeSale(req.params.saleId);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create lot purchase
router.post('/lot-purchases', authenticateToken, authorizeRole(['owner']), async (req, res) => {
  try {
    const { error, value } = validateLotPurchaseData(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const lot = await LotPurchaseService.createLotPurchase({
      ...value,
      createdBy: req.user.id
    });

    res.status(201).json(lot);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add stones to lot
router.post('/lot-purchases/:lotId/stones', authenticateToken, authorizeRole(['owner']), async (req, res) => {
  try {
    const stones = await LotPurchaseService.addStonesToLot(req.params.lotId, req.body.stones);
    res.status(201).json(stones);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get lot purchase summary
router.get('/lot-purchases/:lotId/summary', authenticateToken, async (req, res) => {
  try {
    const summary = await LotPurchaseService.getLotPurchaseSummary(req.params.lotId);
    if (!summary) {
      return res.status(404).json({ error: 'Lot not found' });
    }
    res.json(summary);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create expense
router.post('/expenses', authenticateToken, async (req, res) => {
  try {
    const { error, value } = validateExpenseData(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const expense = await ExpenseAllocationService.createExpense({
      ...value,
      createdBy: req.user.id
    });

    res.status(201).json(expense);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Allocate expense to stones
router.post('/expenses/:expenseId/allocate-stones', authenticateToken, async (req, res) => {
  try {
    const result = await ExpenseAllocationService.allocateExpenseToStones(
      req.params.expenseId,
      req.body
    );
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Allocate expense to sale
router.post('/expenses/:expenseId/allocate-sale', authenticateToken, async (req, res) => {
  try {
    const { saleId } = req.body;
    if (!saleId) {
      return res.status(400).json({ error: 'saleId is required' });
    }

    const result = await ExpenseAllocationService.allocateExpenseToSale(
      req.params.expenseId,
      saleId
    );
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get expense allocations
router.get('/expenses/:expenseId/allocations', authenticateToken, async (req, res) => {
  try {
    const allocations = await ExpenseAllocationService.getExpenseAllocations(req.params.expenseId);
    res.json(allocations);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get expense summary by category
router.get('/expenses/summary/category', authenticateToken, async (req, res) => {
  try {
    const { startDate, endDate, branchId } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const summary = await ExpenseAllocationService.getExpenseSummaryByCategory(
      startDate,
      endDate,
      branchId
    );
    res.json(summary);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Validation functions
function validateSaleData(data) {
  const validation = ProfitLossService.validateSaleData(data);
  if (!validation.isValid) {
    return { error: { details: [{ message: validation.errors.join(', ') }] } };
  }
  return { value: data };
}

function validateLotPurchaseData(data) {
  const validation = LotPurchaseService.validateLotPurchaseData(data);
  if (!validation.isValid) {
    return { error: { details: [{ message: validation.errors.join(', ') }] } };
  }
  return { value: data };
}

function validateExpenseData(data) {
  const validation = ExpenseAllocationService.validateExpenseData(data);
  if (!validation.isValid) {
    return { error: { details: [{ message: validation.errors.join(', ') }] } };
  }
  return { value: data };
}

module.exports = router;
