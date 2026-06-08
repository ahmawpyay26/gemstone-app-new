const Lot = require('../models/Lot');
const Gemstone = require('../models/Gemstone');
const sequelize = require('../config/database');

// Create Lot
exports.createLot = async (req, res) => {
  try {
    const lotData = {
      ...req.body,
      created_by: req.user.userId
    };

    const lot = await Lot.create(lotData);

    res.status(201).json({
      status: 'success',
      data: lot
    });
  } catch (err) {
    console.error('Create lot error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Failed to create lot'
    });
  }
};

// Get All Lots
exports.getAllLots = async (req, res) => {
  try {
    const { status } = req.query;
    const where = {};
    if (status) where.status = status;

    const lots = await Lot.findAll({ where, order: [['created_at', 'DESC']] });

    res.status(200).json({
      status: 'success',
      results: lots.length,
      data: lots
    });
  } catch (err) {
    console.error('Get lots error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch lots'
    });
  }
};

// Split Lot into Individual Stones
exports.splitLot = async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { lot_id, stones } = req.body; // stones is an array of gemstone objects

    const lot = await Lot.findByPk(lot_id, { transaction: t });
    if (!lot) {
      await t.rollback();
      return res.status(404).json({
        status: 'error',
        message: 'Lot not found'
      });
    }

    if (lot.status === 'split') {
      await t.rollback();
      return res.status(400).json({
        status: 'error',
        message: 'Lot has already been split'
      });
    }

    // Create individual gemstones from the lot
    const createdStones = await Promise.all(stones.map(stone => {
      return Gemstone.create({
        ...stone,
        lot_id: lot.id,
        purchase_date: lot.purchase_date,
        created_by: req.user.userId,
        qr_code: stone.qr_code || `GEM-${Date.now()}-${Math.floor(Math.random() * 1000)}`
      }, { transaction: t });
    }));

    // Update lot status
    await lot.update({ status: 'split' }, { transaction: t });

    await t.commit();

    res.status(200).json({
      status: 'success',
      message: 'Lot split successfully',
      data: createdStones
    });
  } catch (err) {
    await t.rollback();
    console.error('Split lot error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Failed to split lot'
    });
  }
};
