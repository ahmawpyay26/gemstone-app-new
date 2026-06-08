const express = require('express');
const router = express.Router();
const lotController = require('../controllers/lot.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);

router.post('/', lotController.createLot);
router.get('/', lotController.getAllLots);
router.post('/split', lotController.splitLot);

module.exports = router;
