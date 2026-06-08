const ExcelJS = require('exceljs');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const fs = require('fs');
const path = require('path');

class ExcelExportService {
  constructor() {
    this.exportsDir = path.join(__dirname, '../exports');
    this.ensureExportsDir();

    // Myanmar language translations
    this.translations = {
      mm: {
        salesReport: 'ရောင်းချမှု အစီရင်ခံစာ',
        inventoryReport: 'စတော့ အစီရင်ခံစာ',
        expenseReport: 'ကုန်ကျစရိတ် အစီရင်ခံစာ',
        profitLossReport: 'အမြတ်နှင့် ဆုံးရှုံးမှု အစီရင်ခံစာ',
        date: 'နေ့စွဲ',
        branch: 'ခုခံ',
        buyer: 'ဝယ်ယူသူ',
        quantity: 'အရေအတွက်',
        carats: 'ကာရက်',
        totalSales: 'စုစုပေါင်းရောင်းချမှု',
        totalCost: 'စုစုပေါင်းကုန်ကျစရိတ်',
        totalProfit: 'စုစုပေါင်းအမြတ်',
        profitMargin: 'အမြတ်အခွင့်အလမ်း',
        stoneName: 'ကျောက်ခွဲ အမည်',
        type: 'အမျိုးအစား',
        color: 'အရောင်',
        clarity: 'တရားဆိုင်ရာ',
        price: 'စျေးနှုန်း',
        status: 'အခြေအနေ',
        category: 'အမျိုးအစား',
        description: 'အဖြ述်',
        amount: 'ပမာဏ',
        revenue: 'ရောင်းချမှု',
        cost: 'ကုန်ကျစရိတ်',
        profit: 'အမြတ်',
        expenses: 'ကုန်ကျစရိတ်များ',
        netProfit: 'သန့်စင်သောအမြတ်'
      },
      en: {
        salesReport: 'Sales Report',
        inventoryReport: 'Inventory Report',
        expenseReport: 'Expense Report',
        profitLossReport: 'Profit & Loss Report',
        date: 'Date',
        branch: 'Branch',
        buyer: 'Buyer',
        quantity: 'Quantity',
        carats: 'Carats',
        totalSales: 'Total Sales',
        totalCost: 'Total Cost',
        totalProfit: 'Total Profit',
        profitMargin: 'Profit Margin %',
        stoneName: 'Stone Name',
        type: 'Type',
        color: 'Color',
        clarity: 'Clarity',
        price: 'Price',
        status: 'Status',
        category: 'Category',
        description: 'Description',
        amount: 'Amount',
        revenue: 'Revenue',
        cost: 'Cost',
        profit: 'Profit',
        expenses: 'Expenses',
        netProfit: 'Net Profit'
      }
    };
  }

  ensureExportsDir() {
    if (!fs.existsSync(this.exportsDir)) {
      fs.mkdirSync(this.exportsDir, { recursive: true });
    }
  }

  /**
   * Export Sales Data to Excel
   */
  async exportSalesData(startDate, endDate, branchId = null, language = 'mm') {
    try {
      const exportId = uuidv4();
      const filename = `sales-export-${startDate}-${endDate}-${exportId}.xlsx`;
      const filepath = path.join(this.exportsDir, filename);

      // Get sales data
      let query = `
        SELECT 
          s.id, s.sale_date, s.buyer_name, s.buyer_type,
          s.total_stones, s.total_carats, s.total_sale_price,
          SUM(si.total_cost) as total_cost,
          SUM(si.profit) as total_profit,
          AVG(si.profit_margin_percentage) as profit_margin
        FROM sales s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        WHERE s.sale_date BETWEEN ? AND ?
      `;

      const params = [startDate, endDate];

      if (branchId) {
        query += ` AND s.branch_id = ?`;
        params.push(branchId);
      }

      query += ` GROUP BY s.id ORDER BY s.sale_date DESC`;

      const [sales] = await db.execute(query, params);

      // Create workbook
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet(this.translations[language].salesReport);

      // Add headers
      const headers = [
        this.translations[language].date,
        this.translations[language].buyer,
        this.translations[language].quantity,
        this.translations[language].carats,
        this.translations[language].totalSales,
        this.translations[language].totalCost,
        this.translations[language].totalProfit,
        this.translations[language].profitMargin
      ];

      const headerRow = worksheet.addRow(headers);
      headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4472C4' } };

      // Add data rows
      sales.forEach(sale => {
        worksheet.addRow([
          sale.sale_date,
          sale.buyer_name,
          sale.total_stones,
          sale.total_carats.toFixed(2),
          sale.total_sale_price.toFixed(2),
          (sale.total_cost || 0).toFixed(2),
          (sale.total_profit || 0).toFixed(2),
          (sale.profit_margin || 0).toFixed(2)
        ]);
      });

      // Set column widths
      worksheet.columns = [
        { width: 15 },
        { width: 20 },
        { width: 12 },
        { width: 12 },
        { width: 15 },
        { width: 15 },
        { width: 15 },
        { width: 15 }
      ];

      // Add summary row
      const summary = this.calculateSalesSummary(sales);
      const summaryRow = worksheet.addRow([
        'TOTAL',
        '',
        summary.totalStones,
        summary.totalCarats.toFixed(2),
        summary.totalRevenue.toFixed(2),
        summary.totalCost.toFixed(2),
        summary.totalProfit.toFixed(2),
        summary.avgProfitMargin.toFixed(2)
      ]);
      summaryRow.font = { bold: true };
      summaryRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFE699' } };

      // Save file
      await workbook.xlsx.writeFile(filepath);

      // Record export
      await this.recordExport(exportId, 'SALES', filename, 'EXCEL', `${startDate}-${endDate}`, branchId);

      return {
        exportId,
        filename,
        filepath,
        format: 'EXCEL'
      };
    } catch (error) {
      throw new Error(`Failed to export sales data: ${error.message}`);
    }
  }

  /**
   * Export Inventory Data to Excel
   */
  async exportInventoryData(branchId = null, language = 'mm') {
    try {
      const exportId = uuidv4();
      const filename = `inventory-export-${exportId}.xlsx`;
      const filepath = path.join(this.exportsDir, filename);

      // Get inventory data
      let query = `
        SELECT 
          g.id, g.name, g.type, g.color, g.clarity,
          g.carat_weight, g.cost_basis, g.status,
          lp.lot_number, b.name as branch_name
        FROM gemstones g
        LEFT JOIN lot_purchases lp ON g.lot_purchase_id = lp.id
        LEFT JOIN branches b ON g.branch_id = b.id
        WHERE g.status IN ('INVENTORY', 'RESERVED')
      `;

      const params = [];

      if (branchId) {
        query += ` AND g.branch_id = ?`;
        params.push(branchId);
      }

      query += ` ORDER BY g.created_at DESC`;

      const [inventory] = await db.execute(query, params);

      // Create workbook
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet(this.translations[language].inventoryReport);

      // Add headers
      const headers = [
        this.translations[language].stoneName,
        this.translations[language].type,
        this.translations[language].color,
        this.translations[language].clarity,
        this.translations[language].carats,
        this.translations[language].price,
        this.translations[language].status,
        'Lot Number'
      ];

      const headerRow = worksheet.addRow(headers);
      headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF70AD47' } };

      // Add data rows
      inventory.forEach(item => {
        worksheet.addRow([
          item.name || item.type,
          item.type,
          item.color,
          item.clarity,
          item.carat_weight.toFixed(2),
          item.cost_basis.toFixed(2),
          item.status,
          item.lot_number || ''
        ]);
      });

      // Set column widths
      worksheet.columns = [
        { width: 20 },
        { width: 15 },
        { width: 12 },
        { width: 12 },
        { width: 12 },
        { width: 15 },
        { width: 12 },
        { width: 15 }
      ];

      // Add summary
      const summary = this.calculateInventorySummary(inventory);
      const summaryRow = worksheet.addRow([
        'TOTAL',
        '',
        '',
        '',
        summary.totalCarats.toFixed(2),
        summary.totalValue.toFixed(2),
        '',
        ''
      ]);
      summaryRow.font = { bold: true };
      summaryRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFE699' } };

      // Save file
      await workbook.xlsx.writeFile(filepath);

      // Record export
      await this.recordExport(exportId, 'INVENTORY', filename, 'EXCEL', new Date().toISOString().split('T')[0], branchId);

      return {
        exportId,
        filename,
        filepath,
        format: 'EXCEL'
      };
    } catch (error) {
      throw new Error(`Failed to export inventory data: ${error.message}`);
    }
  }

  /**
   * Export Expense Data to Excel
   */
  async exportExpenseData(startDate, endDate, branchId = null, language = 'mm') {
    try {
      const exportId = uuidv4();
      const filename = `expenses-export-${startDate}-${endDate}-${exportId}.xlsx`;
      const filepath = path.join(this.exportsDir, filename);

      // Get expense data
      let query = `
        SELECT 
          e.id, e.expense_date, e.category, e.description,
          e.amount, e.allocation_method, e.status,
          COUNT(DISTINCT ea.gemstone_id) as allocated_stones
        FROM expenses e
        LEFT JOIN expense_allocations ea ON e.id = ea.expense_id
        WHERE e.expense_date BETWEEN ? AND ?
      `;

      const params = [startDate, endDate];

      if (branchId) {
        query += ` AND e.branch_id = ?`;
        params.push(branchId);
      }

      query += ` GROUP BY e.id ORDER BY e.expense_date DESC`;

      const [expenses] = await db.execute(query, params);

      // Create workbook
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet(this.translations[language].expenseReport);

      // Add headers
      const headers = [
        this.translations[language].date,
        this.translations[language].category,
        this.translations[language].description,
        this.translations[language].amount,
        'Allocation Method',
        'Allocated Stones',
        this.translations[language].status
      ];

      const headerRow = worksheet.addRow(headers);
      headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFC55A11' } };

      // Add data rows
      expenses.forEach(expense => {
        worksheet.addRow([
          expense.expense_date,
          expense.category,
          expense.description || '',
          expense.amount.toFixed(2),
          expense.allocation_method,
          expense.allocated_stones,
          expense.status
        ]);
      });

      // Set column widths
      worksheet.columns = [
        { width: 15 },
        { width: 15 },
        { width: 20 },
        { width: 15 },
        { width: 18 },
        { width: 15 },
        { width: 12 }
      ];

      // Add summary
      const summary = this.calculateExpenseSummary(expenses);
      const summaryRow = worksheet.addRow([
        'TOTAL',
        '',
        '',
        summary.totalExpenses.toFixed(2),
        '',
        '',
        ''
      ]);
      summaryRow.font = { bold: true };
      summaryRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFE699' } };

      // Save file
      await workbook.xlsx.writeFile(filepath);

      // Record export
      await this.recordExport(exportId, 'EXPENSE', filename, 'EXCEL', `${startDate}-${endDate}`, branchId);

      return {
        exportId,
        filename,
        filepath,
        format: 'EXCEL'
      };
    } catch (error) {
      throw new Error(`Failed to export expense data: ${error.message}`);
    }
  }

  /**
   * Export Profit/Loss Data to Excel
   */
  async exportProfitLossData(startDate, endDate, branchId = null, language = 'mm') {
    try {
      const exportId = uuidv4();
      const filename = `profit-loss-export-${startDate}-${endDate}-${exportId}.xlsx`;
      const filepath = path.join(this.exportsDir, filename);

      // Get P&L data
      let query = `
        SELECT 
          DATE(s.sale_date) as date,
          COUNT(DISTINCT s.id) as sales_count,
          SUM(s.total_sale_price) as total_revenue,
          SUM(si.total_cost) as total_cost,
          SUM(si.profit) as total_profit,
          SUM(e.amount) as total_expenses
        FROM sales s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        LEFT JOIN expenses e ON DATE(e.expense_date) = DATE(s.sale_date)
        WHERE s.sale_date BETWEEN ? AND ?
      `;

      const params = [startDate, endDate];

      if (branchId) {
        query += ` AND s.branch_id = ?`;
        params.push(branchId);
      }

      query += ` GROUP BY DATE(s.sale_date) ORDER BY s.sale_date DESC`;

      const [data] = await db.execute(query, params);

      // Create workbook
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet(this.translations[language].profitLossReport);

      // Add headers
      const headers = [
        this.translations[language].date,
        'Sales Count',
        this.translations[language].revenue,
        this.translations[language].cost,
        this.translations[language].profit,
        this.translations[language].expenses,
        this.translations[language].netProfit
      ];

      const headerRow = worksheet.addRow(headers);
      headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4472C4' } };

      // Add data rows
      data.forEach(row => {
        const netProfit = (row.total_profit || 0) - (row.total_expenses || 0);
        worksheet.addRow([
          row.date,
          row.sales_count,
          (row.total_revenue || 0).toFixed(2),
          (row.total_cost || 0).toFixed(2),
          (row.total_profit || 0).toFixed(2),
          (row.total_expenses || 0).toFixed(2),
          netProfit.toFixed(2)
        ]);
      });

      // Set column widths
      worksheet.columns = [
        { width: 15 },
        { width: 12 },
        { width: 15 },
        { width: 15 },
        { width: 15 },
        { width: 15 },
        { width: 15 }
      ];

      // Add summary
      const summary = this.calculateProfitLossSummary(data);
      const summaryRow = worksheet.addRow([
        'TOTAL',
        '',
        summary.totalRevenue.toFixed(2),
        summary.totalCost.toFixed(2),
        summary.totalProfit.toFixed(2),
        summary.totalExpenses.toFixed(2),
        summary.netProfit.toFixed(2)
      ]);
      summaryRow.font = { bold: true };
      summaryRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFE699' } };

      // Save file
      await workbook.xlsx.writeFile(filepath);

      // Record export
      await this.recordExport(exportId, 'PROFIT_LOSS', filename, 'EXCEL', `${startDate}-${endDate}`, branchId);

      return {
        exportId,
        filename,
        filepath,
        format: 'EXCEL'
      };
    } catch (error) {
      throw new Error(`Failed to export profit/loss data: ${error.message}`);
    }
  }

  /**
   * Calculate sales summary
   */
  calculateSalesSummary(sales) {
    return {
      totalSales: sales.length,
      totalStones: sales.reduce((sum, s) => sum + (s.total_stones || 0), 0),
      totalCarats: sales.reduce((sum, s) => sum + (s.total_carats || 0), 0),
      totalRevenue: sales.reduce((sum, s) => sum + (s.total_sale_price || 0), 0),
      totalCost: sales.reduce((sum, s) => sum + (s.total_cost || 0), 0),
      totalProfit: sales.reduce((sum, s) => sum + (s.total_profit || 0), 0),
      avgProfitMargin: sales.length > 0 
        ? sales.reduce((sum, s) => sum + (s.profit_margin || 0), 0) / sales.length 
        : 0
    };
  }

  /**
   * Calculate inventory summary
   */
  calculateInventorySummary(inventory) {
    return {
      totalStones: inventory.length,
      totalCarats: inventory.reduce((sum, i) => sum + (i.carat_weight || 0), 0),
      totalValue: inventory.reduce((sum, i) => sum + (i.cost_basis || 0), 0),
      avgCarat: inventory.length > 0 
        ? inventory.reduce((sum, i) => sum + (i.carat_weight || 0), 0) / inventory.length 
        : 0
    };
  }

  /**
   * Calculate expense summary
   */
  calculateExpenseSummary(expenses) {
    return {
      totalExpenses: expenses.reduce((sum, e) => sum + (e.amount || 0), 0),
      expenseCount: expenses.length
    };
  }

  /**
   * Calculate P&L summary
   */
  calculateProfitLossSummary(data) {
    return {
      totalRevenue: data.reduce((sum, d) => sum + (d.total_revenue || 0), 0),
      totalCost: data.reduce((sum, d) => sum + (d.total_cost || 0), 0),
      totalProfit: data.reduce((sum, d) => sum + (d.total_profit || 0), 0),
      totalExpenses: data.reduce((sum, d) => sum + (d.total_expenses || 0), 0),
      netProfit: data.reduce((sum, d) => sum + (d.total_profit || 0), 0) - data.reduce((sum, d) => sum + (d.total_expenses || 0), 0)
    };
  }

  /**
   * Record export action
   */
  async recordExport(exportId, reportType, filename, format, period, branchId) {
    try {
      const query = `
        INSERT INTO export_logs (
          id, report_type, filename, format, period, branch_id, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, NOW())
      `;

      await db.execute(query, [exportId, reportType, filename, format, period, branchId]);
    } catch (error) {
      console.error('Failed to record export:', error);
    }
  }
}

module.exports = new ExcelExportService();
