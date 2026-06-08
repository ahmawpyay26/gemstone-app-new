const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const LotPurchaseService = require('./lotPurchase.service');

class LotSplittingService {
  /**
   * Split a stone into multiple pieces
   */
  async splitStone(gemstoneId, splitData) {
    const {
      splitReason,
      resultingStones, // Array of {caratWeight, name, type, color, clarity}
      allocationMethod = 'EQUAL_WEIGHT',
      createdBy
    } = splitData;

    // Get original stone
    const stone = await this.getStone(gemstoneId);
    if (!stone) {
      throw new Error('Stone not found');
    }

    if (stone.status === 'WASTE') {
      throw new Error('Cannot split a waste stone');
    }

    if (stone.status === 'SOLD') {
      throw new Error('Cannot split a sold stone');
    }

    // Validate resulting stones
    const totalResultingCarats = resultingStones.reduce((sum, s) => sum + s.caratWeight, 0);
    if (totalResultingCarats > stone.carat_weight) {
      throw new Error('Total resulting carats exceeds original stone weight');
    }

    const wasteCarats = stone.carat_weight - totalResultingCarats;
    const wasteCost = (wasteCarats / stone.carat_weight) * stone.cost_basis;

    // Calculate cost allocation for resulting stones
    const costAllocations = this.calculateSplitCostAllocation(
      stone.cost_basis,
      resultingStones,
      wasteCarats,
      allocationMethod
    );

    const splitId = uuidv4();

    try {
      // Create split record
      const splitQuery = `
        INSERT INTO lot_splits (
          id, original_stone_id, split_date, split_reason,
          original_carat, original_cost, allocation_method,
          resulting_stone_count, total_resulting_carat, total_resulting_cost,
          waste_carat, waste_cost, created_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      const totalResultingCost = costAllocations.reduce((sum, a) => sum + a.allocatedCost, 0);

      await db.execute(splitQuery, [
        splitId,
        gemstoneId,
        new Date(),
        splitReason,
        stone.carat_weight,
        stone.cost_basis,
        allocationMethod,
        resultingStones.length,
        totalResultingCarats,
        totalResultingCost,
        wasteCarats,
        wasteCost,
        createdBy
      ]);

      // Create resulting stones
      const createdStones = [];
      for (let i = 0; i < resultingStones.length; i++) {
        const resultingStone = resultingStones[i];
        const allocation = costAllocations[i];
        const newStoneId = uuidv4();

        const stoneQuery = `
          INSERT INTO gemstones (
            id, lot_purchase_id, parent_stone_id, split_date,
            name, type, color, clarity, carat_weight, cost_basis,
            status, branch_id
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        await db.execute(stoneQuery, [
          newStoneId,
          stone.lot_purchase_id,
          gemstoneId,
          new Date(),
          resultingStone.name || `Split ${i + 1}`,
          resultingStone.type,
          resultingStone.color,
          resultingStone.clarity,
          resultingStone.caratWeight,
          allocation.allocatedCost,
          'INVENTORY',
          stone.branch_id
        ]);

        // Record cost basis history
        await LotPurchaseService.recordCostBasisHistory(
          newStoneId,
          'SPLIT',
          null,
          allocation.allocatedCost,
          splitId,
          'LOT_SPLIT',
          `Split from stone ${gemstoneId}`,
          createdBy
        );

        // Create split result record
        const resultQuery = `
          INSERT INTO lot_split_results (
            id, lot_split_id, resulting_stone_id,
            resulting_carat, allocated_cost
          ) VALUES (?, ?, ?, ?, ?)
        `;

        await db.execute(resultQuery, [
          uuidv4(),
          splitId,
          newStoneId,
          resultingStone.caratWeight,
          allocation.allocatedCost
        ]);

        createdStones.push({
          id: newStoneId,
          caratWeight: resultingStone.caratWeight,
          costBasis: allocation.allocatedCost
        });
      }

      // Update original stone status to SPLIT
      await db.execute(
        'UPDATE gemstones SET status = ?, updated_at = NOW() WHERE id = ?',
        ['SPLIT', gemstoneId]
      );

      // Record cost basis history for original stone
      await LotPurchaseService.recordCostBasisHistory(
        gemstoneId,
        'SPLIT',
        stone.cost_basis,
        0,
        splitId,
        'LOT_SPLIT',
        `Stone split into ${resultingStones.length} pieces`,
        createdBy
      );

      return {
        splitId,
        originalStoneId: gemstoneId,
        originalCarats: stone.carat_weight,
        originalCost: stone.cost_basis,
        resultingStones: createdStones,
        wasteCarats,
        wasteCost,
        allocationMethod
      };
    } catch (error) {
      throw new Error(`Failed to split stone: ${error.message}`);
    }
  }

  /**
   * Calculate cost allocation for split stones
   */
  calculateSplitCostAllocation(originalCost, resultingStones, wasteCarats, allocationMethod) {
    const totalResultingCarats = resultingStones.reduce((sum, s) => sum + s.caratWeight, 0);
    const wasteCost = (wasteCarats / (totalResultingCarats + wasteCarats)) * originalCost;
    const allocatableCost = originalCost - wasteCost;

    if (allocationMethod === 'EQUAL_WEIGHT') {
      // Allocate based on carat weight
      return resultingStones.map(stone => ({
        caratWeight: stone.caratWeight,
        allocatedCost: (stone.caratWeight / totalResultingCarats) * allocatableCost
      }));
    } else if (allocationMethod === 'EQUAL_COUNT') {
      // Equal allocation per stone
      const costPerStone = allocatableCost / resultingStones.length;
      return resultingStones.map(stone => ({
        caratWeight: stone.caratWeight,
        allocatedCost: costPerStone
      }));
    } else if (allocationMethod === 'CUSTOM') {
      // Assume allocatedCost is provided in resultingStones
      return resultingStones.map(stone => ({
        caratWeight: stone.caratWeight,
        allocatedCost: stone.allocatedCost || 0
      }));
    } else {
      throw new Error('Unknown allocation method');
    }
  }

  /**
   * Get stone details
   */
  async getStone(gemstoneId) {
    try {
      const query = `
        SELECT * FROM gemstones WHERE id = ?
      `;

      const [rows] = await db.execute(query, [gemstoneId]);
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to get stone: ${error.message}`);
    }
  }

  /**
   * Get split history for a stone
   */
  async getSplitHistory(gemstoneId) {
    try {
      const query = `
        SELECT 
          ls.*, 
          COUNT(DISTINCT lsr.id) as resulting_stone_count
        FROM lot_splits ls
        LEFT JOIN lot_split_results lsr ON ls.id = lsr.lot_split_id
        WHERE ls.original_stone_id = ?
        GROUP BY ls.id
        ORDER BY ls.split_date DESC
      `;

      const [rows] = await db.execute(query, [gemstoneId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get split history: ${error.message}`);
    }
  }

  /**
   * Get all resulting stones from a split
   */
  async getSplitResults(splitId) {
    try {
      const query = `
        SELECT 
          lsr.*,
          g.name, g.type, g.color, g.clarity, g.status, g.branch_id
        FROM lot_split_results lsr
        LEFT JOIN gemstones g ON lsr.resulting_stone_id = g.id
        WHERE lsr.lot_split_id = ?
        ORDER BY lsr.created_at ASC
      `;

      const [rows] = await db.execute(query, [splitId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get split results: ${error.message}`);
    }
  }

  /**
   * Get parent stone
   */
  async getParentStone(gemstoneId) {
    try {
      const stone = await this.getStone(gemstoneId);
      if (!stone || !stone.parent_stone_id) {
        return null;
      }

      return await this.getStone(stone.parent_stone_id);
    } catch (error) {
      throw new Error(`Failed to get parent stone: ${error.message}`);
    }
  }

  /**
   * Get all child stones (split results)
   */
  async getChildStones(gemstoneId) {
    try {
      const query = `
        SELECT * FROM gemstones
        WHERE parent_stone_id = ?
        ORDER BY created_at ASC
      `;

      const [rows] = await db.execute(query, [gemstoneId]);
      return rows;
    } catch (error) {
      throw new Error(`Failed to get child stones: ${error.message}`);
    }
  }

  /**
   * Get split lineage (full parent-child tree)
   */
  async getSplitLineage(gemstoneId) {
    try {
      const stone = await this.getStone(gemstoneId);
      if (!stone) {
        return null;
      }

      // Get root stone
      let rootStone = stone;
      while (rootStone.parent_stone_id) {
        rootStone = await this.getStone(rootStone.parent_stone_id);
      }

      // Build tree
      const tree = await this.buildStoneTree(rootStone.id);
      return tree;
    } catch (error) {
      throw new Error(`Failed to get split lineage: ${error.message}`);
    }
  }

  /**
   * Build stone tree recursively
   */
  async buildStoneTree(gemstoneId) {
    const stone = await this.getStone(gemstoneId);
    const children = await this.getChildStones(gemstoneId);

    return {
      id: stone.id,
      name: stone.name,
      caratWeight: stone.carat_weight,
      costBasis: stone.cost_basis,
      status: stone.status,
      children: await Promise.all(children.map(child => this.buildStoneTree(child.id)))
    };
  }

  /**
   * Validate split data
   */
  validateSplitData(data) {
    const errors = [];

    if (!data.resultingStones || data.resultingStones.length === 0) {
      errors.push('At least one resulting stone is required');
    }

    if (data.resultingStones && data.resultingStones.length > 0) {
      data.resultingStones.forEach((stone, index) => {
        if (!stone.caratWeight || stone.caratWeight <= 0) {
          errors.push(`Resulting stone ${index + 1} must have positive carat weight`);
        }
      });
    }

    if (!['EQUAL_WEIGHT', 'EQUAL_COUNT', 'CUSTOM'].includes(data.allocationMethod)) {
      errors.push('Invalid allocation method');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = new LotSplittingService();
