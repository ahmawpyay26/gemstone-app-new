const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const LotPurchaseService = require('./lotPurchase.service');

class WasteStoneService {
  /**
   * Mark a stone as waste
   */
  async markAsWaste(gemstoneId, wasteData) {
    const {
      wasteReason,
      wasteCarats = null, // null means full stone is waste
      scrapValue = 0,
      notes,
      createdBy
    } = wasteData;

    const stone = await this.getStone(gemstoneId);
    if (!stone) {
      throw new Error('Stone not found');
    }

    if (stone.status === 'SOLD') {
      throw new Error('Cannot mark sold stone as waste');
    }

    if (stone.status === 'WASTE') {
      throw new Error('Stone is already marked as waste');
    }

    const isFullWaste = wasteCarats === null || wasteCarats >= stone.carat_weight;
    const actualWasteCarats = isFullWaste ? stone.carat_weight : wasteCarats;
    const wasteCost = (actualWasteCarats / stone.carat_weight) * stone.cost_basis;

    const wasteId = uuidv4();

    try {
      // Create waste record
      const wasteQuery = `
        INSERT INTO waste_stones (
          id, gemstone_id, waste_date, waste_reason,
          original_carat, original_cost, waste_carat, waste_cost,
          remaining_carat, remaining_cost, scrap_value, created_by, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      const remainingCarats = isFullWaste ? null : stone.carat_weight - actualWasteCarats;
      const remainingCost = isFullWaste ? null : stone.cost_basis - wasteCost;

      await db.execute(wasteQuery, [
        wasteId,
        gemstoneId,
        new Date(),
        wasteReason,
        stone.carat_weight,
        stone.cost_basis,
        actualWasteCarats,
        wasteCost,
        remainingCarats,
        remainingCost,
        scrapValue,
        createdBy,
        notes
      ]);

      if (isFullWaste) {
        // Mark stone as waste
        await db.execute(
          `UPDATE gemstones 
           SET status = ?, waste_reason = ?, waste_date = ?, updated_at = NOW()
           WHERE id = ?`,
          ['WASTE', wasteReason, new Date(), gemstoneId]
        );

        // Record cost basis history
        await LotPurchaseService.recordCostBasisHistory(
          gemstoneId,
          'WASTE_ADJUSTMENT',
          stone.cost_basis,
          0,
          wasteId,
          'WASTE_STONE',
          `Full stone marked as waste: ${wasteReason}`,
          createdBy
        );
      } else {
        // Create remaining stone
        const remainingStoneId = uuidv4();
        const stoneQuery = `
          INSERT INTO gemstones (
            id, lot_purchase_id, parent_stone_id, name, type, color, clarity,
            carat_weight, cost_basis, status, branch_id
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        await db.execute(stoneQuery, [
          remainingStoneId,
          stone.lot_purchase_id,
          gemstoneId,
          stone.name + ' (Remaining)',
          stone.type,
          stone.color,
          stone.clarity,
          remainingCarats,
          remainingCost,
          'INVENTORY',
          stone.branch_id
        ]);

        // Mark original stone as waste
        await db.execute(
          `UPDATE gemstones 
           SET status = ?, waste_reason = ?, waste_date = ?, updated_at = NOW()
           WHERE id = ?`,
          ['WASTE', wasteReason, new Date(), gemstoneId]
        );

        // Record cost basis history for original stone
        await LotPurchaseService.recordCostBasisHistory(
          gemstoneId,
          'WASTE_ADJUSTMENT',
          stone.cost_basis,
          0,
          wasteId,
          'WASTE_STONE',
          `Partial waste: ${actualWasteCarats} carats marked as waste`,
          createdBy
        );

        // Record cost basis history for remaining stone
        await LotPurchaseService.recordCostBasisHistory(
          remainingStoneId,
          'WASTE_ADJUSTMENT',
          null,
          remainingCost,
          wasteId,
          'WASTE_STONE',
          `Remaining stone from waste adjustment`,
          createdBy
        );

        return {
          wasteId,
          originalStoneId: gemstoneId,
          wasteCarats: actualWasteCarats,
          wasteCost,
          remainingStoneId,
          remainingCarats,
          remainingCost,
          scrapValue
        };
      }

      return {
        wasteId,
        originalStoneId: gemstoneId,
        wasteCarats: actualWasteCarats,
        wasteCost,
        scrapValue,
        isFullWaste
      };
    } catch (error) {
      throw new Error(`Failed to mark stone as waste: ${error.message}`);
    }
  }

  /**
   * Record scrap value for waste stone
   */
  async recordScrapValue(wasteId, scrapValue) {
    try {
      const query = `
        UPDATE waste_stones
        SET scrap_value = ?, scrap_date = NOW()
        WHERE id = ?
      `;

      await db.execute(query, [scrapValue, wasteId]);

      return { wasteId, scrapValue };
    } catch (error) {
      throw new Error(`Failed to record scrap value: ${error.message}`);
    }
  }

  /**
   * Reallocate waste costs to remaining stones in lot
   */
  async reallocateWasteCosts(lotId, wasteId) {
    try {
      // Get waste details
      const wasteQuery = `SELECT * FROM waste_stones WHERE id = ?`;
      const [wasteRows] = await db.execute(wasteQuery, [wasteId]);
      const waste = wasteRows[0];

      if (!waste) {
        throw new Error('Waste record not found');
      }

      // Get remaining stones in lot
      const stonesQuery = `
        SELECT * FROM gemstones
        WHERE lot_purchase_id = ?
        AND status IN ('INVENTORY', 'RESERVED')
        AND id != ?
      `;
      const [stoneRows] = await db.execute(stonesQuery, [lotId, waste.gemstone_id]);

      if (stoneRows.length === 0) {
        return { reallocatedAmount: 0, affectedStones: 0 };
      }

      // Calculate reallocation
      const totalRemainingCarats = stoneRows.reduce((sum, s) => sum + s.carat_weight, 0);
      const costPerCarat = waste.waste_cost / totalRemainingCarats;

      // Reallocate to each stone
      let affectedStones = 0;
      for (const stone of stoneRows) {
        const additionalCost = stone.carat_weight * costPerCarat;
        const newCostBasis = stone.cost_basis + additionalCost;

        // Update stone cost basis
        await db.execute(
          `UPDATE gemstones SET cost_basis = ?, updated_at = NOW() WHERE id = ?`,
          [newCostBasis, stone.id]
        );

        // Record cost basis history
        await LotPurchaseService.recordCostBasisHistory(
          stone.id,
          'WASTE_ADJUSTMENT',
          stone.cost_basis,
          newCostBasis,
          wasteId,
          'WASTE_REALLOCATION',
          `Waste cost reallocation: ${additionalCost.toFixed(2)}`,
          null
        );

        affectedStones++;
      }

      return {
        reallocatedAmount: waste.waste_cost,
        affectedStones,
        costPerCarat
      };
    } catch (error) {
      throw new Error(`Failed to reallocate waste costs: ${error.message}`);
    }
  }

  /**
   * Get waste record
   */
  async getWasteRecord(wasteId) {
    try {
      const query = `SELECT * FROM waste_stones WHERE id = ?`;
      const [rows] = await db.execute(query, [wasteId]);
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to get waste record: ${error.message}`);
    }
  }

  /**
   * Get waste stones for a lot
   */
  async getLotWasteStones(lotId) {
    try {
      const query = `
        SELECT ws.* FROM waste_stones ws
        JOIN gemstones g ON ws.gemstone_id = g.id
        WHERE g.lot_purchase_id = ?
        ORDER BY ws.waste_date DESC
      `;

      const [rows] = await db.execute(query, [lotId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get lot waste stones: ${error.message}`);
    }
  }

  /**
   * Get waste summary for a lot
   */
  async getLotWasteSummary(lotId) {
    try {
      const query = `
        SELECT 
          COUNT(DISTINCT ws.id) as waste_count,
          SUM(ws.waste_carat) as total_waste_carats,
          SUM(ws.waste_cost) as total_waste_cost,
          SUM(ws.scrap_value) as total_scrap_value
        FROM waste_stones ws
        JOIN gemstones g ON ws.gemstone_id = g.id
        WHERE g.lot_purchase_id = ?
      `;

      const [rows] = await db.execute(query, [lotId]);
      return rows[0] || {
        waste_count: 0,
        total_waste_carats: 0,
        total_waste_cost: 0,
        total_scrap_value: 0
      };
    } catch (error) {
      throw new Error(`Failed to get lot waste summary: ${error.message}`);
    }
  }

  /**
   * Reverse waste marking
   */
  async reverseWasteMarking(gemstoneId) {
    try {
      const stone = await this.getStone(gemstoneId);
      if (!stone) {
        throw new Error('Stone not found');
      }

      if (stone.status !== 'WASTE') {
        throw new Error('Stone is not marked as waste');
      }

      // Update stone status back to inventory
      await db.execute(
        `UPDATE gemstones 
         SET status = ?, waste_reason = NULL, waste_date = NULL, updated_at = NOW()
         WHERE id = ?`,
        ['INVENTORY', gemstoneId]
      );

      return { id: gemstoneId, status: 'INVENTORY' };
    } catch (error) {
      throw new Error(`Failed to reverse waste marking: ${error.message}`);
    }
  }

  /**
   * Get stone details
   */
  async getStone(gemstoneId) {
    try {
      const query = `SELECT * FROM gemstones WHERE id = ?`;
      const [rows] = await db.execute(query, [gemstoneId]);
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to get stone: ${error.message}`);
    }
  }

  /**
   * Calculate waste impact on lot
   */
  async calculateWasteImpact(lotId) {
    try {
      const query = `
        SELECT 
          lp.id,
          lp.total_cost,
          lp.total_carats,
          SUM(CASE WHEN g.status = 'WASTE' THEN g.carat_weight ELSE 0 END) as waste_carats,
          SUM(CASE WHEN g.status = 'WASTE' THEN g.cost_basis ELSE 0 END) as waste_cost,
          SUM(CASE WHEN g.status = 'INVENTORY' THEN g.carat_weight ELSE 0 END) as inventory_carats,
          SUM(CASE WHEN g.status = 'INVENTORY' THEN g.cost_basis ELSE 0 END) as inventory_cost,
          SUM(CASE WHEN g.status = 'SOLD' THEN g.carat_weight ELSE 0 END) as sold_carats,
          SUM(CASE WHEN g.status = 'SOLD' THEN g.cost_basis ELSE 0 END) as sold_cost
        FROM lot_purchases lp
        LEFT JOIN gemstones g ON lp.id = g.lot_purchase_id
        WHERE lp.id = ?
        GROUP BY lp.id
      `;

      const [rows] = await db.execute(query, [lotId]);
      const summary = rows[0];

      if (!summary) {
        return null;
      }

      const wastePercentage = (summary.waste_carats / summary.total_carats) * 100;
      const wasteImpact = (summary.waste_cost / summary.total_cost) * 100;

      return {
        totalCost: summary.total_cost,
        totalCarats: summary.total_carats,
        wasteCarats: summary.waste_carats,
        wasteCost: summary.waste_cost,
        wastePercentage,
        wasteImpact,
        inventoryCarats: summary.inventory_carats,
        inventoryCost: summary.inventory_cost,
        soldCarats: summary.sold_carats,
        soldCost: summary.sold_cost
      };
    } catch (error) {
      throw new Error(`Failed to calculate waste impact: ${error.message}`);
    }
  }

  /**
   * Validate waste data
   */
  validateWasteData(data) {
    const errors = [];

    if (!data.wasteReason) {
      errors.push('Waste reason is required');
    }

    if (data.wasteCarats && data.wasteCarats <= 0) {
      errors.push('Waste carats must be positive');
    }

    if (data.scrapValue && data.scrapValue < 0) {
      errors.push('Scrap value cannot be negative');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = new WasteStoneService();
