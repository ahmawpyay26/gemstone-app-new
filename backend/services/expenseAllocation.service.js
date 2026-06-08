const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const LotPurchaseService = require('./lotPurchase.service');

class ExpenseAllocationService {
  /**
   * Create an expense
   */
  async createExpense(expenseData) {
    const {
      expenseDate,
      branchId,
      category,
      description,
      amount,
      allocationMethod = 'EQUAL_STONES',
      relatedLotId,
      relatedSaleId,
      relatedGemstoneIds = [],
      notes,
      createdBy
    } = expenseData;

    // Validate input
    if (!category || !amount || amount <= 0) {
      throw new Error('Invalid expense data');
    }

    const expenseId = uuidv4();

    try {
      const query = `
        INSERT INTO expenses (
          id, expense_date, branch_id, category, description, amount,
          allocation_method, related_lot_id, related_sale_id,
          related_gemstone_ids, status, created_by, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      await db.execute(query, [
        expenseId,
        expenseDate || new Date(),
        branchId,
        category,
        description,
        amount,
        allocationMethod,
        relatedLotId,
        relatedSaleId,
        JSON.stringify(relatedGemstoneIds),
        'PENDING',
        createdBy,
        notes
      ]);

      return {
        id: expenseId,
        category,
        amount,
        allocationMethod,
        status: 'PENDING'
      };
    } catch (error) {
      throw new Error(`Failed to create expense: ${error.message}`);
    }
  }

  /**
   * Allocate expense to stones
   */
  async allocateExpenseToStones(expenseId, allocationData) {
    const {
      allocationMethod = 'EQUAL_STONES',
      targetStones = [], // Array of stone IDs or lot ID
      customAllocations = {} // {stoneId: amount}
    } = allocationData;

    // Get expense
    const expense = await this.getExpense(expenseId);
    if (!expense) {
      throw new Error('Expense not found');
    }

    if (expense.status === 'ALLOCATED') {
      throw new Error('Expense is already allocated');
    }

    let stonesToAllocate = [];

    // Determine stones to allocate
    if (expense.related_lot_id && targetStones.length === 0) {
      // Allocate to all stones in lot
      stonesToAllocate = await this.getLotStones(expense.related_lot_id);
    } else if (targetStones.length > 0) {
      stonesToAllocate = await this.getStones(targetStones);
    } else {
      throw new Error('No target stones specified for allocation');
    }

    if (stonesToAllocate.length === 0) {
      throw new Error('No stones found for allocation');
    }

    // Calculate allocations
    const allocations = this.calculateExpenseAllocations(
      expense.amount,
      stonesToAllocate,
      allocationMethod,
      customAllocations
    );

    // Record allocations
    const allocationIds = [];
    let totalAllocated = 0;

    try {
      for (const allocation of allocations) {
        const allocationId = uuidv4();
        const query = `
          INSERT INTO expense_allocations (
            id, expense_id, gemstone_id, lot_purchase_id,
            allocated_amount, allocation_percentage, allocation_basis
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
        `;

        const stone = stonesToAllocate.find(s => s.id === allocation.stoneId);

        await db.execute(query, [
          allocationId,
          expenseId,
          allocation.stoneId,
          stone.lot_purchase_id,
          allocation.allocatedAmount,
          allocation.allocationPercentage,
          allocationMethod
        ]);

        // Update stone cost basis
        const newCostBasis = stone.cost_basis + allocation.allocatedAmount;
        await db.execute(
          `UPDATE gemstones SET cost_basis = ?, updated_at = NOW() WHERE id = ?`,
          [newCostBasis, allocation.stoneId]
        );

        // Record cost basis history
        await LotPurchaseService.recordCostBasisHistory(
          allocation.stoneId,
          'EXPENSE_ALLOCATION',
          stone.cost_basis,
          newCostBasis,
          expenseId,
          'EXPENSE',
          `${expense.category} expense allocation: ${allocation.allocatedAmount.toFixed(2)}`,
          null
        );

        allocationIds.push(allocationId);
        totalAllocated += allocation.allocatedAmount;
      }

      // Update expense status
      await db.execute(
        `UPDATE expenses SET status = ?, updated_at = NOW() WHERE id = ?`,
        ['ALLOCATED', expenseId]
      );

      return {
        expenseId,
        allocationMethod,
        allocatedStones: stonesToAllocate.length,
        totalAllocated,
        allocations
      };
    } catch (error) {
      throw new Error(`Failed to allocate expense: ${error.message}`);
    }
  }

  /**
   * Calculate expense allocations
   */
  calculateExpenseAllocations(
    totalExpense,
    stones,
    allocationMethod,
    customAllocations = {}
  ) {
    if (allocationMethod === 'EQUAL_STONES') {
      // Equal allocation per stone
      const amountPerStone = totalExpense / stones.length;
      return stones.map(stone => ({
        stoneId: stone.id,
        allocatedAmount: amountPerStone,
        allocationPercentage: (amountPerStone / totalExpense) * 100
      }));
    } else if (allocationMethod === 'EQUAL_WEIGHT') {
      // Allocate based on carat weight
      const totalCarats = stones.reduce((sum, s) => sum + s.carat_weight, 0);
      return stones.map(stone => ({
        stoneId: stone.id,
        allocatedAmount: (stone.carat_weight / totalCarats) * totalExpense,
        allocationPercentage: (stone.carat_weight / totalCarats) * 100
      }));
    } else if (allocationMethod === 'PERCENTAGE') {
      // Allocate based on custom percentages
      return stones.map(stone => {
        const percentage = customAllocations[stone.id] || 0;
        return {
          stoneId: stone.id,
          allocatedAmount: (percentage / 100) * totalExpense,
          allocationPercentage: percentage
        };
      });
    } else if (allocationMethod === 'MANUAL') {
      // Manual allocation
      return stones.map(stone => ({
        stoneId: stone.id,
        allocatedAmount: customAllocations[stone.id] || 0,
        allocationPercentage: ((customAllocations[stone.id] || 0) / totalExpense) * 100
      }));
    } else {
      throw new Error('Unknown allocation method');
    }
  }

  /**
   * Allocate expense to sale
   */
  async allocateExpenseToSale(expenseId, saleId) {
    const expense = await this.getExpense(expenseId);
    if (!expense) {
      throw new Error('Expense not found');
    }

    // Get sale items
    const saleItems = await this.getSaleItems(saleId);
    if (saleItems.length === 0) {
      throw new Error('No items found in sale');
    }

    // Allocate to sale items
    const allocations = this.calculateExpenseAllocations(
      expense.amount,
      saleItems,
      'EQUAL_WEIGHT'
    );

    try {
      for (const allocation of allocations) {
        // Update sale item allocated expenses
        const saleItem = saleItems.find(s => s.id === allocation.stoneId);
        const newAllocatedExpenses = (saleItem.allocated_expenses || 0) + allocation.allocatedAmount;

        await db.execute(
          `UPDATE sale_items SET allocated_expenses = ?, updated_at = NOW() WHERE id = ?`,
          [newAllocatedExpenses, allocation.stoneId]
        );
      }

      // Update expense status
      await db.execute(
        `UPDATE expenses SET status = ?, related_sale_id = ?, updated_at = NOW() WHERE id = ?`,
        ['ALLOCATED', saleId, expenseId]
      );

      return {
        expenseId,
        saleId,
        allocatedItems: saleItems.length,
        totalAllocated: expense.amount
      };
    } catch (error) {
      throw new Error(`Failed to allocate expense to sale: ${error.message}`);
    }
  }

  /**
   * Get expense details
   */
  async getExpense(expenseId) {
    try {
      const query = `SELECT * FROM expenses WHERE id = ?`;
      const [rows] = await db.execute(query, [expenseId]);
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to get expense: ${error.message}`);
    }
  }

  /**
   * Get expense allocations
   */
  async getExpenseAllocations(expenseId) {
    try {
      const query = `
        SELECT 
          ea.*,
          g.name as stone_name,
          g.carat_weight,
          g.cost_basis
        FROM expense_allocations ea
        LEFT JOIN gemstones g ON ea.gemstone_id = g.id
        WHERE ea.expense_id = ?
        ORDER BY ea.created_at ASC
      `;

      const [rows] = await db.execute(query, [expenseId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get expense allocations: ${error.message}`);
    }
  }

  /**
   * Get expenses for a lot
   */
  async getLotExpenses(lotId) {
    try {
      const query = `
        SELECT * FROM expenses
        WHERE related_lot_id = ?
        ORDER BY expense_date DESC
      `;

      const [rows] = await db.execute(query, [lotId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get lot expenses: ${error.message}`);
    }
  }

  /**
   * Get expenses for a sale
   */
  async getSaleExpenses(saleId) {
    try {
      const query = `
        SELECT * FROM expenses
        WHERE related_sale_id = ?
        ORDER BY expense_date DESC
      `;

      const [rows] = await db.execute(query, [saleId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get sale expenses: ${error.message}`);
    }
  }

  /**
   * Get lot stones
   */
  async getLotStones(lotId) {
    try {
      const query = `
        SELECT * FROM gemstones
        WHERE lot_purchase_id = ? AND status IN ('INVENTORY', 'RESERVED')
        ORDER BY stone_number ASC
      `;

      const [rows] = await db.execute(query, [lotId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get lot stones: ${error.message}`);
    }
  }

  /**
   * Get stones by IDs
   */
  async getStones(stoneIds) {
    try {
      const placeholders = stoneIds.map(() => '?').join(',');
      const query = `
        SELECT * FROM gemstones
        WHERE id IN (${placeholders}) AND status IN ('INVENTORY', 'RESERVED')
      `;

      const [rows] = await db.execute(query, stoneIds);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get stones: ${error.message}`);
    }
  }

  /**
   * Get sale items
   */
  async getSaleItems(saleId) {
    try {
      const query = `
        SELECT * FROM sale_items
        WHERE sale_id = ?
        ORDER BY created_at ASC
      `;

      const [rows] = await db.execute(query, [saleId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get sale items: ${error.message}`);
    }
  }

  /**
   * Get expense summary by category
   */
  async getExpenseSummaryByCategory(startDate, endDate, branchId = null) {
    try {
      let query = `
        SELECT 
          category,
          COUNT(*) as expense_count,
          SUM(amount) as total_amount,
          AVG(amount) as avg_amount
        FROM expenses
        WHERE expense_date BETWEEN ? AND ?
      `;

      const params = [startDate, endDate];

      if (branchId) {
        query += ` AND branch_id = ?`;
        params.push(branchId);
      }

      query += ` GROUP BY category ORDER BY total_amount DESC`;

      const [rows] = await db.execute(query, params);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get expense summary: ${error.message}`);
    }
  }

  /**
   * Validate expense data
   */
  validateExpenseData(data) {
    const errors = [];

    if (!data.category) {
      errors.push('Category is required');
    }

    if (!data.amount || data.amount <= 0) {
      errors.push('Amount must be positive');
    }

    const validCategories = ['WORKER', 'MACHINE', 'FUEL_OIL', 'TOOLS', 'BROKER_COMMISSION', 'OTHER'];
    if (data.category && !validCategories.includes(data.category)) {
      errors.push('Invalid expense category');
    }

    const validMethods = ['EQUAL_STONES', 'EQUAL_WEIGHT', 'MANUAL', 'PERCENTAGE'];
    if (data.allocationMethod && !validMethods.includes(data.allocationMethod)) {
      errors.push('Invalid allocation method');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = new ExpenseAllocationService();
