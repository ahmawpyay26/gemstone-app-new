const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

class FinancialValidationService {
  /**
   * Perform comprehensive financial reconciliation
   */
  async performReconciliation(branchId = null, reconciliationDate = new Date()) {
    const reconciliationId = uuidv4();
    const errors = [];
    const warnings = [];

    try {
      // 1. Validate inventory valuation
      const inventoryValidation = await this.validateInventoryValuation(branchId);
      if (!inventoryValidation.isValid) {
        errors.push(...inventoryValidation.errors);
      }
      if (inventoryValidation.warnings.length > 0) {
        warnings.push(...inventoryValidation.warnings);
      }

      // 2. Validate cost basis consistency
      const costBasisValidation = await this.validateCostBasisConsistency(branchId);
      if (!costBasisValidation.isValid) {
        errors.push(...costBasisValidation.errors);
      }
      if (costBasisValidation.warnings.length > 0) {
        warnings.push(...costBasisValidation.warnings);
      }

      // 3. Validate lot integrity
      const lotValidation = await this.validateLotIntegrity(branchId);
      if (!lotValidation.isValid) {
        errors.push(...lotValidation.errors);
      }
      if (lotValidation.warnings.length > 0) {
        warnings.push(...lotValidation.warnings);
      }

      // 4. Validate sales consistency
      const salesValidation = await this.validateSalesConsistency(branchId);
      if (!salesValidation.isValid) {
        errors.push(...salesValidation.errors);
      }
      if (salesValidation.warnings.length > 0) {
        warnings.push(...salesValidation.warnings);
      }

      // 5. Validate expense allocations
      const expenseValidation = await this.validateExpenseAllocations(branchId);
      if (!expenseValidation.isValid) {
        errors.push(...expenseValidation.errors);
      }
      if (expenseValidation.warnings.length > 0) {
        warnings.push(...expenseValidation.warnings);
      }

      // 6. Validate waste handling
      const wasteValidation = await this.validateWasteHandling(branchId);
      if (!wasteValidation.isValid) {
        errors.push(...wasteValidation.errors);
      }
      if (wasteValidation.warnings.length > 0) {
        warnings.push(...wasteValidation.warnings);
      }

      // Get inventory valuation
      const inventoryValuation = await this.getInventoryValuation(branchId);

      // Determine validation status
      const validationStatus = errors.length === 0 ? 'PASSED' : 'FAILED';

      // Save reconciliation record
      const query = `
        INSERT INTO financial_reconciliation (
          id, reconciliation_date, branch_id,
          total_stones_in_inventory, total_carats_in_inventory,
          total_cost_basis_inventory, validation_status,
          validation_errors, validation_warnings, reconciliation_notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      await db.execute(query, [
        reconciliationId,
        reconciliationDate,
        branchId,
        inventoryValuation.totalStones,
        inventoryValuation.totalCarats,
        inventoryValuation.totalCost,
        validationStatus,
        JSON.stringify(errors),
        JSON.stringify(warnings),
        `Reconciliation performed with ${errors.length} errors and ${warnings.length} warnings`
      ]);

      return {
        reconciliationId,
        validationStatus,
        errors,
        warnings,
        inventoryValuation,
        summary: {
          totalErrors: errors.length,
          totalWarnings: warnings.length,
          isValid: errors.length === 0
        }
      };
    } catch (error) {
      throw new Error(`Failed to perform reconciliation: ${error.message}`);
    }
  }

  /**
   * Validate inventory valuation
   */
  async validateInventoryValuation(branchId = null) {
    try {
      const errors = [];
      const warnings = [];

      // Check for stones with zero or negative cost basis
      let query = `
        SELECT id, name, cost_basis FROM gemstones
        WHERE status IN ('INVENTORY', 'RESERVED')
        AND cost_basis <= 0
      `;

      const params = [];

      if (branchId) {
        query += ` AND branch_id = ?`;
        params.push(branchId);
      }

      const [invalidStones] = await db.execute(query, params);
      if (invalidStones.length > 0) {
        errors.push(`Found ${invalidStones.length} stones with invalid cost basis`);
      }

      // Check for stones with missing cost basis
      query = `
        SELECT COUNT(*) as count FROM gemstones
        WHERE status IN ('INVENTORY', 'RESERVED')
        AND (cost_basis IS NULL OR cost_basis = 0)
      `;

      const [missingCostRows] = await db.execute(query, []);
      if (missingCostRows[0].count > 0) {
        warnings.push(`${missingCostRows[0].count} stones have missing or zero cost basis`);
      }

      return {
        isValid: errors.length === 0,
        errors,
        warnings
      };
    } catch (error) {
      throw new Error(`Failed to validate inventory valuation: ${error.message}`);
    }
  }

  /**
   * Validate cost basis consistency
   */
  async validateCostBasisConsistency(branchId = null) {
    try {
      const errors = [];
      const warnings = [];

      // Check for stones with mismatched cost basis after splits
      const query = `
        SELECT 
          ls.id,
          ls.original_stone_id,
          ls.original_cost,
          SUM(lsr.allocated_cost) as total_allocated_cost,
          ls.waste_cost,
          (ls.original_cost - (SUM(lsr.allocated_cost) + ls.waste_cost)) as difference
        FROM lot_splits ls
        LEFT JOIN lot_split_results lsr ON ls.id = lsr.lot_split_id
        GROUP BY ls.id
        HAVING ABS(difference) > 0.01
      `;

      const [inconsistencies] = await db.execute(query, []);
      if (inconsistencies.length > 0) {
        errors.push(`Found ${inconsistencies.length} splits with cost basis inconsistencies`);
        inconsistencies.forEach(inc => {
          warnings.push(`Split ${inc.id}: Original cost ${inc.original_cost}, allocated ${inc.total_allocated_cost + inc.waste_cost}`);
        });
      }

      return {
        isValid: errors.length === 0,
        errors,
        warnings
      };
    } catch (error) {
      throw new Error(`Failed to validate cost basis consistency: ${error.message}`);
    }
  }

  /**
   * Validate lot integrity
   */
  async validateLotIntegrity(branchId = null) {
    try {
      const errors = [];
      const warnings = [];

      // Check for lots with mismatched stone counts
      let query = `
        SELECT 
          lp.id,
          lp.lot_number,
          lp.total_stones,
          COUNT(g.id) as actual_stones,
          lp.total_carats,
          SUM(g.carat_weight) as actual_carats,
          lp.total_cost,
          SUM(g.cost_basis) as actual_cost
        FROM lot_purchases lp
        LEFT JOIN gemstones g ON lp.id = g.lot_purchase_id
        WHERE lp.status IN ('ACTIVE', 'SPLIT')
        GROUP BY lp.id
        HAVING actual_stones != lp.total_stones
      `;

      const params = [];

      if (branchId) {
        query += ` AND g.branch_id = ?`;
        params.push(branchId);
      }

      const [mismatchedLots] = await db.execute(query, params);
      if (mismatchedLots.length > 0) {
        errors.push(`Found ${mismatchedLots.length} lots with mismatched stone counts`);
        mismatchedLots.forEach(lot => {
          warnings.push(`Lot ${lot.lot_number}: Expected ${lot.total_stones} stones, found ${lot.actual_stones}`);
        });
      }

      return {
        isValid: errors.length === 0,
        errors,
        warnings
      };
    } catch (error) {
      throw new Error(`Failed to validate lot integrity: ${error.message}`);
    }
  }

  /**
   * Validate sales consistency
   */
  async validateSalesConsistency(branchId = null) {
    try {
      const errors = [];
      const warnings = [];

      // Check for sales with mismatched item counts
      let query = `
        SELECT 
          s.id,
          s.total_stones,
          COUNT(si.id) as actual_items,
          s.total_carats,
          SUM(si.carat_weight) as actual_carats,
          s.total_sale_price,
          SUM(si.sale_price) as actual_sale_price
        FROM sales s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        WHERE s.status IN ('PENDING', 'CONFIRMED', 'COMPLETED')
        GROUP BY s.id
        HAVING actual_items != s.total_stones OR ABS(actual_sale_price - s.total_sale_price) > 0.01
      `;

      const params = [];

      if (branchId) {
        query += ` AND s.branch_id = ?`;
        params.push(branchId);
      }

      const [mismatchedSales] = await db.execute(query, params);
      if (mismatchedSales.length > 0) {
        errors.push(`Found ${mismatchedSales.length} sales with mismatched items or prices`);
      }

      // Check for sold stones not marked as SOLD
      query = `
        SELECT COUNT(*) as count FROM sale_items si
        JOIN gemstones g ON si.gemstone_id = g.id
        WHERE g.status != 'SOLD'
      `;

      const [unsolvedStones] = await db.execute(query, []);
      if (unsolvedStones[0].count > 0) {
        warnings.push(`${unsolvedStones[0].count} stones in sales are not marked as SOLD`);
      }

      return {
        isValid: errors.length === 0,
        errors,
        warnings
      };
    } catch (error) {
      throw new Error(`Failed to validate sales consistency: ${error.message}`);
    }
  }

  /**
   * Validate expense allocations
   */
  async validateExpenseAllocations(branchId = null) {
    try {
      const errors = [];
      const warnings = [];

      // Check for unallocated expenses
      let query = `
        SELECT COUNT(*) as count FROM expenses
        WHERE status = 'PENDING'
      `;

      const params = [];

      if (branchId) {
        query += ` AND branch_id = ?`;
        params.push(branchId);
      }

      const [unallocatedRows] = await db.execute(query, params);
      if (unallocatedRows[0].count > 0) {
        warnings.push(`${unallocatedRows[0].count} expenses are pending allocation`);
      }

      // Check for expense allocations that exceed expense amount
      query = `
        SELECT 
          e.id,
          e.amount,
          SUM(ea.allocated_amount) as total_allocated
        FROM expenses e
        LEFT JOIN expense_allocations ea ON e.id = ea.expense_id
        WHERE e.status = 'ALLOCATED'
        GROUP BY e.id
        HAVING total_allocated > e.amount + 0.01
      `;

      const [overallocated] = await db.execute(query, []);
      if (overallocated.length > 0) {
        errors.push(`Found ${overallocated.length} expenses with over-allocation`);
      }

      return {
        isValid: errors.length === 0,
        errors,
        warnings
      };
    } catch (error) {
      throw new Error(`Failed to validate expense allocations: ${error.message}`);
    }
  }

  /**
   * Validate waste handling
   */
  async validateWasteHandling(branchId = null) {
    try {
      const errors = [];
      const warnings = [];

      // Check for waste stones with invalid cost
      let query = `
        SELECT COUNT(*) as count FROM waste_stones
        WHERE waste_cost > original_cost
      `;

      const [invalidWaste] = await db.execute(query, []);
      if (invalidWaste[0].count > 0) {
        errors.push(`Found ${invalidWaste[0].count} waste records with invalid costs`);
      }

      // Check for waste stones without reason
      query = `
        SELECT COUNT(*) as count FROM waste_stones
        WHERE waste_reason IS NULL OR waste_reason = ''
      `;

      const [missingReason] = await db.execute(query, []);
      if (missingReason[0].count > 0) {
        warnings.push(`${missingReason[0].count} waste stones have no reason recorded`);
      }

      return {
        isValid: errors.length === 0,
        errors,
        warnings
      };
    } catch (error) {
      throw new Error(`Failed to validate waste handling: ${error.message}`);
    }
  }

  /**
   * Get inventory valuation
   */
  async getInventoryValuation(branchId = null) {
    try {
      let query = `
        SELECT 
          COUNT(*) as total_stones,
          SUM(carat_weight) as total_carats,
          SUM(cost_basis) as total_cost
        FROM gemstones
        WHERE status IN ('INVENTORY', 'RESERVED')
      `;

      const params = [];

      if (branchId) {
        query += ` AND branch_id = ?`;
        params.push(branchId);
      }

      const [rows] = await db.execute(query, params);
      const result = rows[0];

      return {
        totalStones: result.total_stones || 0,
        totalCarats: result.total_carats || 0,
        totalCost: result.total_cost || 0
      };
    } catch (error) {
      throw new Error(`Failed to get inventory valuation: ${error.message}`);
    }
  }

  /**
   * Check financial anomalies
   */
  async checkFinancialAnomalies(branchId = null) {
    try {
      const anomalies = [];

      // Check for unusually high profit margins
      const query1 = `
        SELECT 
          si.sale_id,
          AVG(si.profit_margin_percentage) as avg_margin
        FROM sale_items si
        WHERE si.profit_margin_percentage > 100
        GROUP BY si.sale_id
      `;

      const [highMargins] = await db.execute(query1, []);
      if (highMargins.length > 0) {
        anomalies.push({
          type: 'HIGH_PROFIT_MARGIN',
          count: highMargins.length,
          details: highMargins
        });
      }

      // Check for negative profit margins
      const query2 = `
        SELECT 
          si.sale_id,
          AVG(si.profit_margin_percentage) as avg_margin
        FROM sale_items si
        WHERE si.profit_margin_percentage < -50
        GROUP BY si.sale_id
      `;

      const [negativeMargins] = await db.execute(query2, []);
      if (negativeMargins.length > 0) {
        anomalies.push({
          type: 'NEGATIVE_PROFIT_MARGIN',
          count: negativeMargins.length,
          details: negativeMargins
        });
      }

      // Check for high waste percentage
      const query3 = `
        SELECT 
          lp.id,
          lp.lot_number,
          SUM(ws.waste_carat) / lp.total_carats * 100 as waste_percentage
        FROM lot_purchases lp
        LEFT JOIN gemstones g ON lp.id = g.lot_purchase_id
        LEFT JOIN waste_stones ws ON g.id = ws.gemstone_id
        GROUP BY lp.id
        HAVING waste_percentage > 30
      `;

      const [highWaste] = await db.execute(query3, []);
      if (highWaste.length > 0) {
        anomalies.push({
          type: 'HIGH_WASTE_PERCENTAGE',
          count: highWaste.length,
          details: highWaste
        });
      }

      return anomalies;
    } catch (error) {
      throw new Error(`Failed to check financial anomalies: ${error.message}`);
    }
  }

  /**
   * Get reconciliation history
   */
  async getReconciliationHistory(branchId = null, limit = 10) {
    try {
      let query = `
        SELECT * FROM financial_reconciliation
        WHERE 1=1
      `;

      const params = [];

      if (branchId) {
        query += ` AND branch_id = ?`;
        params.push(branchId);
      }

      query += ` ORDER BY reconciliation_date DESC LIMIT ?`;
      params.push(limit);

      const [rows] = await db.execute(query, params);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get reconciliation history: ${error.message}`);
    }
  }
}

module.exports = new FinancialValidationService();
