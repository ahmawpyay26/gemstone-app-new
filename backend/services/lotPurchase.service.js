const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

class LotPurchaseService {
  /**
   * Create a new lot purchase
   */
  async createLotPurchase(purchaseData) {
    const {
      purchaseDate,
      supplierId,
      supplierName,
      lotNumber,
      totalStones,
      totalCarats,
      totalCost,
      notes,
      createdBy
    } = purchaseData;

    // Validate input
    if (!lotNumber || !totalStones || !totalCarats || !totalCost) {
      throw new Error('Missing required fields for lot purchase');
    }

    if (totalStones <= 0 || totalCarats <= 0 || totalCost <= 0) {
      throw new Error('Lot values must be positive');
    }

    const lotId = uuidv4();
    const costPerCarat = totalCost / totalCarats;
    const costPerStone = totalCost / totalStones;

    try {
      const query = `
        INSERT INTO lot_purchases (
          id, purchase_date, supplier_id, supplier_name, lot_number,
          total_stones, total_carats, total_cost, status, notes, created_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      await db.execute(query, [
        lotId,
        purchaseDate || new Date(),
        supplierId,
        supplierName,
        lotNumber,
        totalStones,
        totalCarats,
        totalCost,
        'ACTIVE',
        notes,
        createdBy
      ]);

      return {
        id: lotId,
        lotNumber,
        totalStones,
        totalCarats,
        totalCost,
        costPerCarat,
        costPerStone,
        status: 'ACTIVE'
      };
    } catch (error) {
      throw new Error(`Failed to create lot purchase: ${error.message}`);
    }
  }

  /**
   * Add individual stones to a lot
   */
  async addStonesToLot(lotId, stones) {
    const lot = await this.getLotPurchase(lotId);
    
    if (!lot) {
      throw new Error('Lot not found');
    }

    if (stones.length !== lot.total_stones) {
      throw new Error(`Expected ${lot.total_stones} stones, got ${stones.length}`);
    }

    const insertedStones = [];

    try {
      for (let i = 0; i < stones.length; i++) {
        const stone = stones[i];
        const stoneId = uuidv4();

        // Allocate cost based on weight
        const costBasis = (stone.carat_weight / lot.total_carats) * lot.total_cost;

        const query = `
          INSERT INTO gemstones (
            id, lot_purchase_id, stone_number, name, type, color, clarity,
            carat_weight, cost_basis, status, branch_id
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        await db.execute(query, [
          stoneId,
          lotId,
          i + 1,
          stone.name || `Stone ${i + 1}`,
          stone.type,
          stone.color,
          stone.clarity,
          stone.carat_weight,
          costBasis,
          'INVENTORY',
          stone.branch_id
        ]);

        // Record cost basis history
        await this.recordCostBasisHistory(
          stoneId,
          'INITIAL',
          null,
          costBasis,
          lotId,
          'LOT_PURCHASE'
        );

        insertedStones.push({
          id: stoneId,
          stoneNumber: i + 1,
          caratWeight: stone.carat_weight,
          costBasis
        });
      }

      return insertedStones;
    } catch (error) {
      throw new Error(`Failed to add stones to lot: ${error.message}`);
    }
  }

  /**
   * Get lot purchase details
   */
  async getLotPurchase(lotId) {
    try {
      const query = `
        SELECT * FROM lot_purchases WHERE id = ?
      `;

      const [rows] = await db.execute(query, [lotId]);
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to get lot purchase: ${error.message}`);
    }
  }

  /**
   * Get all stones in a lot
   */
  async getLotStones(lotId) {
    try {
      const query = `
        SELECT 
          id, lot_purchase_id, stone_number, name, type, color, clarity,
          carat_weight, cost_basis, status, branch_id, created_at
        FROM gemstones
        WHERE lot_purchase_id = ?
        ORDER BY stone_number ASC
      `;

      const [rows] = await db.execute(query, [lotId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get lot stones: ${error.message}`);
    }
  }

  /**
   * Calculate cost allocation for stones
   */
  calculateCostAllocation(totalCost, stones, allocationMethod = 'WEIGHT') {
    if (allocationMethod === 'WEIGHT') {
      // Allocate based on carat weight
      const totalCarats = stones.reduce((sum, s) => sum + s.carat_weight, 0);
      return stones.map(stone => ({
        stoneId: stone.id,
        caratWeight: stone.carat_weight,
        allocatedCost: (stone.carat_weight / totalCarats) * totalCost
      }));
    } else if (allocationMethod === 'EQUAL_COUNT') {
      // Equal allocation per stone
      const costPerStone = totalCost / stones.length;
      return stones.map(stone => ({
        stoneId: stone.id,
        caratWeight: stone.carat_weight,
        allocatedCost: costPerStone
      }));
    } else {
      throw new Error('Unknown allocation method');
    }
  }

  /**
   * Get lot purchase summary
   */
  async getLotPurchaseSummary(lotId) {
    try {
      const query = `
        SELECT 
          lp.id,
          lp.lot_number,
          lp.purchase_date,
          lp.total_stones,
          lp.total_carats,
          lp.total_cost,
          lp.status,
          COUNT(DISTINCT g.id) as stones_count,
          SUM(CASE WHEN g.status = 'INVENTORY' THEN 1 ELSE 0 END) as inventory_count,
          SUM(CASE WHEN g.status = 'SOLD' THEN 1 ELSE 0 END) as sold_count,
          SUM(CASE WHEN g.status = 'WASTE' THEN 1 ELSE 0 END) as waste_count,
          SUM(CASE WHEN g.status = 'INVENTORY' THEN g.carat_weight ELSE 0 END) as inventory_carats,
          SUM(CASE WHEN g.status = 'SOLD' THEN g.carat_weight ELSE 0 END) as sold_carats,
          SUM(CASE WHEN g.status = 'WASTE' THEN g.carat_weight ELSE 0 END) as waste_carats,
          SUM(CASE WHEN g.status = 'INVENTORY' THEN g.cost_basis ELSE 0 END) as inventory_cost,
          SUM(CASE WHEN g.status = 'SOLD' THEN g.cost_basis ELSE 0 END) as sold_cost,
          SUM(CASE WHEN g.status = 'WASTE' THEN g.cost_basis ELSE 0 END) as waste_cost
        FROM lot_purchases lp
        LEFT JOIN gemstones g ON lp.id = g.lot_purchase_id
        WHERE lp.id = ?
        GROUP BY lp.id
      `;

      const [rows] = await db.execute(query, [lotId]);
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to get lot purchase summary: ${error.message}`);
    }
  }

  /**
   * Record cost basis history
   */
  async recordCostBasisHistory(
    gemstoneId,
    changeType,
    previousCost,
    newCost,
    relatedTransactionId,
    relatedTransactionType,
    notes,
    createdBy
  ) {
    try {
      const historyId = uuidv4();
      const query = `
        INSERT INTO cost_basis_history (
          id, gemstone_id, change_type, change_date, previous_cost_basis,
          new_cost_basis, cost_change, related_transaction_id,
          related_transaction_type, created_by, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      const costChange = previousCost ? newCost - previousCost : newCost;

      await db.execute(query, [
        historyId,
        gemstoneId,
        changeType,
        new Date(),
        previousCost,
        newCost,
        costChange,
        relatedTransactionId,
        relatedTransactionType,
        createdBy,
        notes
      ]);

      return historyId;
    } catch (error) {
      throw new Error(`Failed to record cost basis history: ${error.message}`);
    }
  }

  /**
   * Get cost basis history for a stone
   */
  async getCostBasisHistory(gemstoneId) {
    try {
      const query = `
        SELECT * FROM cost_basis_history
        WHERE gemstone_id = ?
        ORDER BY change_date DESC
      `;

      const [rows] = await db.execute(query, [gemstoneId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get cost basis history: ${error.message}`);
    }
  }

  /**
   * Update lot status
   */
  async updateLotStatus(lotId, status) {
    try {
      const query = `
        UPDATE lot_purchases
        SET status = ?, updated_at = NOW()
        WHERE id = ?
      `;

      await db.execute(query, [status, lotId]);

      return { id: lotId, status };
    } catch (error) {
      throw new Error(`Failed to update lot status: ${error.message}`);
    }
  }

  /**
   * Get all active lots
   */
  async getActiveLots(branchId = null) {
    try {
      let query = `
        SELECT lp.*, 
          COUNT(DISTINCT g.id) as total_stones_added,
          SUM(g.carat_weight) as total_carats_added
        FROM lot_purchases lp
        LEFT JOIN gemstones g ON lp.id = g.lot_purchase_id
        WHERE lp.status IN ('ACTIVE', 'SPLIT')
      `;

      const params = [];

      if (branchId) {
        query += ` AND g.branch_id = ?`;
        params.push(branchId);
      }

      query += ` GROUP BY lp.id ORDER BY lp.purchase_date DESC`;

      const [rows] = await db.execute(query, params);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get active lots: ${error.message}`);
    }
  }

  /**
   * Validate lot purchase data
   */
  validateLotPurchaseData(data) {
    const errors = [];

    if (!data.lotNumber) errors.push('Lot number is required');
    if (!data.totalStones || data.totalStones <= 0) errors.push('Total stones must be positive');
    if (!data.totalCarats || data.totalCarats <= 0) errors.push('Total carats must be positive');
    if (!data.totalCost || data.totalCost <= 0) errors.push('Total cost must be positive');

    // Check for reasonable values
    if (data.totalStones > 10000) errors.push('Total stones seems unreasonably high');
    if (data.totalCarats > 100000) errors.push('Total carats seems unreasonably high');

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = new LotPurchaseService();
