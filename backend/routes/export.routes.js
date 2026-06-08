const express = require('express');
const router = express.Router();
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');
const PDFReportGenerator = require('../services/pdfReportGenerator.service');
const ExcelExportService = require('../services/excelExportService');
const fs = require('fs');
const path = require('path');

// PDF Export Endpoints

/**
 * Generate Daily Sales Report (PDF)
 */
router.get('/pdf/daily-sales', authMiddleware, async (req, res) => {
  try {
    const { date, branchId, language = 'mm' } = req.query;

    if (!date) {
      return res.status(400).json({ error: 'Date is required' });
    }

    const report = await PDFReportGenerator.generateDailySalesReport(date, branchId, language);
    
    // Send file
    res.download(report.filepath, report.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Generate Monthly Sales Report (PDF)
 */
router.get('/pdf/monthly-sales', authMiddleware, async (req, res) => {
  try {
    const { yearMonth, branchId, language = 'mm' } = req.query;

    if (!yearMonth) {
      return res.status(400).json({ error: 'Year-month is required (YYYY-MM)' });
    }

    const report = await PDFReportGenerator.generateMonthlySalesReport(yearMonth, branchId, language);
    
    res.download(report.filepath, report.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Generate Profit & Loss Report (PDF)
 */
router.get('/pdf/profit-loss', authMiddleware, roleMiddleware(['owner', 'accountant']), async (req, res) => {
  try {
    const { startDate, endDate, branchId, language = 'mm' } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const report = await PDFReportGenerator.generateProfitLossReport(startDate, endDate, branchId, language);
    
    res.download(report.filepath, report.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Generate Inventory Report (PDF)
 */
router.get('/pdf/inventory', authMiddleware, async (req, res) => {
  try {
    const { branchId, language = 'mm' } = req.query;

    const report = await PDFReportGenerator.generateInventoryReport(branchId, language);
    
    res.download(report.filepath, report.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Generate Expense Report (PDF)
 */
router.get('/pdf/expenses', authMiddleware, roleMiddleware(['owner', 'accountant']), async (req, res) => {
  try {
    const { startDate, endDate, branchId, language = 'mm' } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const report = await PDFReportGenerator.generateExpenseReport(startDate, endDate, branchId, language);
    
    res.download(report.filepath, report.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Excel Export Endpoints

/**
 * Export Sales Data (Excel)
 */
router.get('/excel/sales', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate, branchId, language = 'mm' } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const export_data = await ExcelExportService.exportSalesData(startDate, endDate, branchId, language);
    
    res.download(export_data.filepath, export_data.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Export Inventory Data (Excel)
 */
router.get('/excel/inventory', authMiddleware, async (req, res) => {
  try {
    const { branchId, language = 'mm' } = req.query;

    const export_data = await ExcelExportService.exportInventoryData(branchId, language);
    
    res.download(export_data.filepath, export_data.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Export Expense Data (Excel)
 */
router.get('/excel/expenses', authMiddleware, roleMiddleware(['owner', 'accountant']), async (req, res) => {
  try {
    const { startDate, endDate, branchId, language = 'mm' } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const export_data = await ExcelExportService.exportExpenseData(startDate, endDate, branchId, language);
    
    res.download(export_data.filepath, export_data.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Export Profit/Loss Data (Excel)
 */
router.get('/excel/profit-loss', authMiddleware, roleMiddleware(['owner', 'accountant']), async (req, res) => {
  try {
    const { startDate, endDate, branchId, language = 'mm' } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const export_data = await ExcelExportService.exportProfitLossData(startDate, endDate, branchId, language);
    
    res.download(export_data.filepath, export_data.filename);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get export history
 */
router.get('/history', authMiddleware, roleMiddleware(['owner', 'accountant']), async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    const query = `
      SELECT * FROM export_logs
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `;

    const [exports] = await db.execute(query, [parseInt(limit), parseInt(offset)]);

    res.json({
      data: exports,
      total: exports.length,
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Delete export file (Owner only)
 */
router.delete('/:exportId', authMiddleware, roleMiddleware(['owner']), async (req, res) => {
  try {
    const { exportId } = req.params;

    // Get export record
    const query = `SELECT * FROM export_logs WHERE id = ?`;
    const [exports] = await db.execute(query, [exportId]);

    if (exports.length === 0) {
      return res.status(404).json({ error: 'Export not found' });
    }

    const export_record = exports[0];
    const filepath = path.join(__dirname, '../reports', export_record.filename);

    // Delete file if exists
    if (fs.existsSync(filepath)) {
      fs.unlinkSync(filepath);
    }

    // Delete record
    const deleteQuery = `DELETE FROM export_logs WHERE id = ?`;
    await db.execute(deleteQuery, [exportId]);

    res.json({ message: 'Export deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
