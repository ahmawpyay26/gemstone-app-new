const Gemstone = require('../models/Gemstone');
const Lot = require('../models/Lot');
const { v4: uuidv4 } = require('uuid');

// Create Gemstone
exports.createGemstone = async (req, res) => {
  try {
    const gemstoneData = {
      ...req.body,
      qr_code: req.body.qr_code || `GEM-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      created_by: req.user.userId
    };

    const gemstone = await Gemstone.create(gemstoneData);

    res.status(201).json({
      status: 'success',
      data: gemstone
    });
  } catch (err) {
    console.error('Create gemstone error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Failed to create gemstone'
    });
  }
};

// Get All Gemstones
exports.getAllGemstones = async (req, res) => {
  try {
    const { status, type, lot_id } = req.query;
    const where = {};
    if (status) where.status = status;
    if (type) where.type = type;
    if (lot_id) where.lot_id = lot_id;

    const gemstones = await Gemstone.findAll({ where, order: [['created_at', 'DESC']] });

    res.status(200).json({
      status: 'success',
      results: gemstones.length,
      data: gemstones
    });
  } catch (err) {
    console.error('Get gemstones error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch gemstones'
    });
  }
};

// Get Gemstone by ID
exports.getGemstoneById = async (req, res) => {
  try {
    const gemstone = await Gemstone.findByPk(req.params.id);
    if (!gemstone) {
      return res.status(404).json({
        status: 'error',
        message: 'Gemstone not found'
      });
    }
    res.status(200).json({
      status: 'success',
      data: gemstone
    });
  } catch (err) {
    console.error('Get gemstone error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch gemstone'
    });
  }
};

// Update Gemstone
exports.updateGemstone = async (req, res) => {
  try {
    const gemstone = await Gemstone.findByPk(req.params.id);
    if (!gemstone) {
      return res.status(404).json({
        status: 'error',
        message: 'Gemstone not found'
      });
    }

    await gemstone.update(req.body);

    res.status(200).json({
      status: 'success',
      data: gemstone
    });
  } catch (err) {
    console.error('Update gemstone error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update gemstone'
    });
  }
};

// Delete Gemstone
exports.deleteGemstone = async (req, res) => {
  try {
    const gemstone = await Gemstone.findByPk(req.params.id);
    if (!gemstone) {
      return res.status(404).json({
        status: 'error',
        message: 'Gemstone not found'
      });
    }

    await gemstone.destroy();

    res.status(204).json({
      status: 'success',
      data: null
    });
  } catch (err) {
    console.error('Delete gemstone error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete gemstone'
    });
  }
};
