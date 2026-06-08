const express = require('express');
const router = express.Router();
const gemstoneController = require('../controllers/gemstone.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);

router.post('/', gemstoneController.createGemstone);
router.get('/', gemstoneController.getAllGemstones);
router.get('/:id', gemstoneController.getGemstoneById);
router.put('/:id', gemstoneController.updateGemstone);
router.delete('/:id', gemstoneController.deleteGemstone);

module.exports = router;
