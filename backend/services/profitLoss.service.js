const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

class ProfitLossService {
  /**
   * Create a sale
   */
  async createSale(saleData) {
    const {
      saleDate,
      branchId,
      buyerId,
      buyerName,
      buyerType = 'RETAIL',
      totalStones,
      totalCarats,
      totalSalePrice,
      brokerCommission = 0,
      brokerCommissionPercentage = 0,
      notes,
      createdBy
    } = saleData;

    // Validate input
    if (!totalStones || !totalCarats || !totalSalePrice) {
      throw new Error('Invalid sale data');
    }

    const saleId = uuidv4();

    try {
      const query = `
        INSERT INTO sales (
          id, sale_date, branch_id, buyer_id, buyer_name, buyer_type,
          total_stones, total_carats, total_sale_price,
          broker_commission, broker_commission_percentage,
          status, created_by, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      await db.execute(query, [
        saleId,
        saleDate || new Date(),
        branchId,
        buyerId,
        buyerName,
        buyerType,
        totalStones,
        totalCarats,
        totalSalePrice,
        brokerCommission,
        brokerCommissionPercentage,
        'PENDING',
        createdBy,
        notes
      ]);

      return {
        id: saleId,
        totalStones,
        totalCarats,
        totalSalePrice,
        status: 'PENDING'
      };
    } catch (error) {
      throw new Error(`Failed to create sale: ${error.message}`);
    }
  }

  /**
   * Add item to sale
   */
  async addSaleItem(saleId, itemData) {
    const {
      gemstoneId,
      caratWeight,
      salePrice,
      costBasis,
      allocatedExpenses = 0
    } = itemData;

    const itemId = uuidv4();

    try {
      const query = `
        INSERT INTO sale_items (
          id, sale_id, gemstone_id, carat_weight, sale_price,
          cost_basis, allocated_expenses
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      `;

      await db.execute(query, [
        itemId,
        saleId,
        gemstoneId,
        caratWeight,
        salePrice,
        costBasis,
        allocatedExpenses
      ]);

      // Update gemstone status
      await db.execute(
        `UPDATE gemstones SET status = ?, updated_at = NOW() WHERE id = ?`,
        ['SOLD', gemstoneId]
      );

      return {
        id: itemId,
        salePrice,
        costBasis,
        profit: salePrice - (costBasis + allocatedExpenses)
      };
    } catch (error) {
      throw new Error(`Failed to add sale item: ${error.message}`);
    }
  }

  /**
   * Calculate profit for a sale
   */
  async calculateSaleProfit(saleId) {
    try {
      const query = `
        SELECT 
          s.id,
          s.total_sale_price,
          SUM(si.cost_basis) as total_cost_basis,
          SUM(si.allocated_expenses) as total_allocated_expenses,
          SUM(si.sale_price - si.total_cost) as total_profit,
          AVG(si.profit_margin_percentage) as avg_profit_margin,
          COUNT(si.id) as item_count
        FROM sales s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        WHERE s.id = ?
        GROUP BY s.id
      `;

      const [rows] = await db.execute(query, [saleId]);
      const result = rows[0];

      if (!result) {
        return null;
      }

      return {
        saleId,
        totalSalePrice: result.total_sale_price,
        totalCostBasis: result.total_cost_basis,
        totalAllocatedExpenses: result.total_allocated_expenses,
        totalCost: result.total_cost_basis + result.total_allocated_expenses,
        totalProfit: result.total_profit,
        profitMarginPercentage: result.avg_profit_margin,
        itemCount: result.item_count
      };
    } catch (error) {
      throw new Error(`Failed to calculate sale profit: ${error.message}`);
    }
  }

  /**
   * Calculate profit for a stone
   */
  async calculateStoneProfit(gemstoneId) {
    try {
      const query = `
        SELECT 
          si.id,
          si.gemstone_id,
          si.sale_price,
          si.cost_basis,
          si.allocated_expenses,
          si.total_cost,
          si.profit,
          si.profit_margin_percentage,
          g.name,
          g.carat_weight,
          s.sale_date
        FROM sale_items si
        LEFT JOIN gemstones g ON si.gemstone_id = g.id
        LEFT JOIN sales s ON si.sale_id = s.id
        WHERE si.gemstone_id = ?
      `;

      const [rows] = await db.execute(query, [gemstoneId]);
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to calculate stone profit: ${error.message}`);
    }
  }

  /**
   * Calculate lot profit
   */
  async calculateLotProfit(lotId) {
    try {
      const query = `
        SELECT 
          lp.id,
          lp.lot_number,
          lp.total_cost,
          lp.total_carats,
          lp.total_stones,
          COUNT(DISTINCT si.sale_id) as sales_count,
          SUM(si.carat_weight) as sold_carats,
          SUM(si.sale_price) as total_sale_price,
          SUM(si.cost_basis) as total_cost_basis,
          SUM(si.allocated_expenses) as total_allocated_expenses,
          SUM(si.total_cost) as total_cost,
          SUM(si.profit) as total_profit,
          AVG(si.profit_margin_percentage) as avg_profit_margin,
          SUM(CASE WHEN g.status = 'INVENTORY' THEN g.carat_weight ELSE 0 END) as inventory_carats,
          SUM(CASE WHEN g.status = 'WASTE' THEN g.carat_weight ELSE 0 END) as waste_carats
        FROM lot_purchases lp
        LEFT JOIN gemstones g ON lp.id = g.lot_purchase_id
        LEFT JOIN sale_items si ON g.id = si.gemstone_id
        WHERE lp.id = ?
        GROUP BY lp.id
      `;

      const [rows] = await db.execute(query, [lotId]);
      const result = rows[0];

      if (!result) {
        return null;
      }

      return {
        lotId,
        lotNumber: result.lot_number,
        totalPurchaseCost: result.total_cost,
        totalCarats: result.total_carats,
        totalStones: result.total_stones,
        soldCarats: result.sold_carats || 0,
        totalSalePrice: result.total_sale_price || 0,
        totalCostBasis: result.total_cost_basis || 0,
        totalAllocatedExpenses: result.total_allocated_expenses || 0,
        totalCost: result.total_cost || 0,
        totalProfit: result.total_profit || 0,
        profitMarginPercentage: result.avg_profit_margin || 0,
        inventoryCarats: result.inventory_carats || 0,
        wasteCarats: result.waste_carats || 0,
        salesCount: result.sales_count || 0
      };
    } catch (error) {
      throw new Error(`Failed to calculate lot profit: ${error.message}`);
    }
  }

  /**
   * Calculate daily profit/loss
   */
  async calculateDailyProfitLoss(businessDate, branchId = null) {
    try {
      // Get or create daily summary
      let dailyId = null;
      const checkQuery = `
        SELECT id FROM daily_profit_loss
        WHERE business_date = ? AND branch_id <=> ?
      `;
      const [existingRows] = await db.execute(checkQuery, [businessDate, branchId]);

      if (existingRows.length > 0) {
        dailyId = existingRows[0].id;
      } else {
        dailyId = uuidv4();
        const insertQuery = `
          INSERT INTO daily_profit_loss (
            id, business_date, branch_id,
            total_sales_count, total_sales_carats, total_sales_revenue,
            total_purchases_count, total_purchases_carats, total_purchases_cost,
            total_expenses, waste_count, waste_carats, waste_cost
          ) VALUES (?, ?, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        `;
        await db.execute(insertQuery, [dailyId, businessDate, branchId]);
      }

      // Calculate sales for the day
      let salesQuery = `
        SELECT 
          COUNT(DISTINCT s.id) as sales_count,
          SUM(s.total_carats) as total_carats,
          SUM(s.total_sale_price) as total_revenue,
          SUM(si.total_cost) as total_cost
        FROM sales s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        WHERE DATE(s.sale_date) = ?
      `;

      const salesParams = [businessDate];

      if (branchId) {
        salesQuery += ` AND s.branch_id = ?`;
        salesParams.push(branchId);
      }

      const [salesRows] = await db.execute(salesQuery, salesParams);
      const salesData = salesRows[0];

      // Calculate purchases for the day
      let purchaseQuery = `
        SELECT 
          COUNT(DISTINCT lp.id) as purchase_count,
          SUM(lp.total_stones) as total_stones,
          SUM(lp.total_carats) as total_carats,
          SUM(lp.total_cost) as total_cost
        FROM lot_purchases lp
        WHERE DATE(lp.created_at) = ?
      `;

      const purchaseParams = [businessDate];

      if (branchId) {
        purchaseQuery += ` AND lp.id IN (SELECT DISTINCT lot_purchase_id FROM gemstones WHERE branch_id = ?)`;
        purchaseParams.push(branchId);
      }

      const [purchaseRows] = await db.execute(purchaseQuery, purchaseParams);
      const purchaseData = purchaseRows[0];

      // Calculate expenses for the day
      let expenseQuery = `
        SELECT SUM(amount) as total_expenses
        FROM expenses
        WHERE DATE(expense_date) = ?
      `;

      const expenseParams = [businessDate];

      if (branchId) {
        expenseQuery += ` AND branch_id = ?`;
        expenseParams.push(branchId);
      }

      const [expenseRows] = await db.execute(expenseQuery, expenseParams);
      const expenseData = expenseRows[0];

      // Calculate waste for the day
      let wasteQuery = `
        SELECT 
          COUNT(DISTINCT ws.id) as waste_count,
          SUM(ws.waste_carat) as waste_carats,
          SUM(ws.waste_cost) as waste_cost
        FROM waste_stones ws
        WHERE DATE(ws.waste_date) = ?
      `;

      const wasteParams = [businessDate];

      if (branchId) {
        wasteQuery += ` AND ws.gemstone_id IN (SELECT id FROM gemstones WHERE branch_id = ?)`;
        wasteParams.push(branchId);
      }

      const [wasteRows] = await db.execute(wasteQuery, wasteParams);
      const wasteData = wasteRows[0];

      // Update daily summary
      const updateQuery = `
        UPDATE daily_profit_loss SET
          total_sales_count = ?,
          total_sales_carats = ?,
          total_sales_revenue = ?,
          total_purchases_count = ?,
          total_purchases_carats = ?,
          total_purchases_cost = ?,
          total_expenses = ?,
          waste_count = ?,
          waste_carats = ?,
          waste_cost = ?
        WHERE id = ?
      `;

      await db.execute(updateQuery, [
        salesData.sales_count || 0,
        salesData.total_carats || 0,
        salesData.total_revenue || 0,
        purchaseData.purchase_count || 0,
        purchaseData.total_carats || 0,
        purchaseData.total_cost || 0,
        expenseData.total_expenses || 0,
        wasteData.waste_count || 0,
        wasteData.waste_carats || 0,
        wasteData.waste_cost || 0,
        dailyId
      ]);

      // Get updated summary
      const summaryQuery = `SELECT * FROM daily_profit_loss WHERE id = ?`;
      const [summaryRows] = await db.execute(summaryQuery, [dailyId]);
      return summaryRows[0];
    } catch (error) {
      throw new Error(`Failed to calculate daily profit/loss: ${error.message}`);
    }
  }

  /**
   * Calculate monthly profit/loss
   */
  async calculateMonthlyProfitLoss(yearMonth, branchId = null) {
    try {
      // Get or create monthly summary
      let monthlyId = null;
      const checkQuery = `
        SELECT id FROM monthly_profit_loss
        WHERE year_month = ? AND branch_id <=> ?
      `;
      const [existingRows] = await db.execute(checkQuery, [yearMonth, branchId]);

      if (existingRows.length > 0) {
        monthlyId = existingRows[0].id;
      } else {
        monthlyId = uuidv4();
        const insertQuery = `
          INSERT INTO monthly_profit_loss (
            id, year_month, branch_id,
            total_sales_count, total_sales_carats, total_sales_revenue,
            total_purchases_count, total_purchases_carats, total_purchases_cost,
            total_expenses, waste_count, waste_carats, waste_cost
          ) VALUES (?, ?, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        `;
        await db.execute(insertQuery, [monthlyId, yearMonth, branchId]);
      }

      // Calculate sales for the month
      let salesQuery = `
        SELECT 
          COUNT(DISTINCT s.id) as sales_count,
          SUM(s.total_carats) as total_carats,
          SUM(s.total_sale_price) as total_revenue,
          SUM(si.total_cost) as total_cost
        FROM sales s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        WHERE DATE_FORMAT(s.sale_date, '%Y-%m') = ?
      `;

      const salesParams = [yearMonth];

      if (branchId) {
        salesQuery += ` AND s.branch_id = ?`;
        salesParams.push(branchId);
      }

      const [salesRows] = await db.execute(salesQuery, salesParams);
      const salesData = salesRows[0];

      // Calculate purchases for the month
      let purchaseQuery = `
        SELECT 
          COUNT(DISTINCT lp.id) as purchase_count,
          SUM(lp.total_stones) as total_stones,
          SUM(lp.total_carats) as total_carats,
          SUM(lp.total_cost) as total_cost
        FROM lot_purchases lp
        WHERE DATE_FORMAT(lp.created_at, '%Y-%m') = ?
      `;

      const purchaseParams = [yearMonth];

      if (branchId) {
        purchaseQuery += ` AND lp.id IN (SELECT DISTINCT lot_purchase_id FROM gemstones WHERE branch_id = ?)`;
        purchaseParams.push(branchId);
      }

      const [purchaseRows] = await db.execute(purchaseQuery, purchaseParams);
      const purchaseData = purchaseRows[0];

      // Calculate expenses for the month
      let expenseQuery = `
        SELECT SUM(amount) as total_expenses
        FROM expenses
        WHERE DATE_FORMAT(expense_date, '%Y-%m') = ?
      `;

      const expenseParams = [yearMonth];

      if (branchId) {
        expenseQuery += ` AND branch_id = ?`;
        expenseParams.push(branchId);
      }

      const [expenseRows] = await db.execute(expenseQuery, expenseParams);
      const expenseData = expenseRows[0];

      // Calculate waste for the month
      let wasteQuery = `
        SELECT 
          COUNT(DISTINCT ws.id) as waste_count,
          SUM(ws.waste_carat) as waste_carats,
          SUM(ws.waste_cost) as waste_cost
        FROM waste_stones ws
        WHERE DATE_FORMAT(ws.waste_date, '%Y-%m') = ?
      `;

      const wasteParams = [yearMonth];

      if (branchId) {
        wasteQuery += ` AND ws.gemstone_id IN (SELECT id FROM gemstones WHERE branch_id = ?)`;
        wasteParams.push(branchId);
      }

      const [wasteRows] = await db.execute(wasteQuery, wasteParams);
      const wasteData = wasteRows[0];

      // Update monthly summary
      const updateQuery = `
        UPDATE monthly_profit_loss SET
          total_sales_count = ?,
          total_sales_carats = ?,
          total_sales_revenue = ?,
          total_purchases_count = ?,
          total_purchases_carats = ?,
          total_purchases_cost = ?,
          total_expenses = ?,
          waste_count = ?,
          waste_carats = ?,
          waste_cost = ?
        WHERE id = ?
      `;

      await db.execute(updateQuery, [
        salesData.sales_count || 0,
        salesData.total_carats || 0,
        salesData.total_revenue || 0,
        purchaseData.purchase_count || 0,
        purchaseData.total_carats || 0,
        purchaseData.total_cost || 0,
        expenseData.total_expenses || 0,
        wasteData.waste_count || 0,
        wasteData.waste_carats || 0,
        wasteData.waste_cost || 0,
        monthlyId
      ]);

      // Get updated summary
      const summaryQuery = `SELECT * FROM monthly_profit_loss WHERE id = ?`;
      const [summaryRows] = await db.execute(summaryQuery, [monthlyId]);
      return summaryRows[0];
    } catch (error) {
      throw new Error(`Failed to calculate monthly profit/loss: ${error.message}`);
    }
  }

  /**
   * Calculate branch profit
   */
  async calculateBranchProfit(branchId, startDate, endDate) {
    try {
      const query = `
        SELECT 
          b.id,
          b.name,
          COUNT(DISTINCT s.id) as sales_count,
          SUM(s.total_carats) as total_carats_sold,
          SUM(s.total_sale_price) as total_revenue,
          SUM(si.total_cost) as total_cost,
          SUM(si.profit) as total_profit,
          AVG(si.profit_margin_percentage) as avg_profit_margin,
          SUM(e.amount) as total_expenses
        FROM branches b
        LEFT JOIN sales s ON b.id = s.branch_id AND s.sale_date BETWEEN ? AND ?
        LEFT JOIN sale_items si ON s.id = si.sale_id
        LEFT JOIN expenses e ON b.id = e.branch_id AND e.expense_date BETWEEN ? AND ?
        WHERE b.id = ?
        GROUP BY b.id
      `;

      const [rows] = await db.execute(query, [startDate, endDate, startDate, endDate, branchId]);
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to calculate branch profit: ${error.message}`);
    }
  }

  /**
   * Confirm sale
   */
  async confirmSale(saleId) {
    try {
      const query = `
        UPDATE sales SET status = ?, updated_at = NOW() WHERE id = ?
      `;

      await db.execute(query, ['CONFIRMED', saleId]);

      // Calculate profit
      const profit = await this.calculateSaleProfit(saleId);

      return {
        saleId,
        status: 'CONFIRMED',
        profit
      };
    } catch (error) {
      throw new Error(`Failed to confirm sale: ${error.message}`);
    }
  }

  /**
   * Complete sale
   */
  async completeSale(saleId) {
    try {
      const query = `
        UPDATE sales SET status = ?, updated_at = NOW() WHERE id = ?
      `;

      await db.execute(query, ['COMPLETED', saleId]);

      return { saleId, status: 'COMPLETED' };
    } catch (error) {
      throw new Error(`Failed to complete sale: ${error.message}`);
    }
  }

  /**
   * Validate sale data
   */
  validateSaleData(data) {
    const errors = [];

    if (!data.totalStones || data.totalStones <= 0) {
      errors.push('Total stones must be positive');
    }

    if (!data.totalCarats || data.totalCarats <= 0) {
      errors.push('Total carats must be positive');
    }

    if (!data.totalSalePrice || data.totalSalePrice <= 0) {
      errors.push('Total sale price must be positive');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = new ProfitLossService();
