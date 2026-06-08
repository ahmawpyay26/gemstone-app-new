const PDFDocument = require('pdfkit');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const fs = require('fs');
const path = require('path');

class PDFReportGenerator {
  constructor() {
    this.reportsDir = path.join(__dirname, '../reports');
    this.ensureReportsDir();
    
    // Myanmar language translations
    this.translations = {
      mm: {
        title: 'ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှု စနစ်',
        salesReport: 'ရောင်းချမှု အစီရင်ခံစာ',
        profitLossReport: 'အမြတ်နှင့် ဆုံးရှုံးမှု အစီရင်ခံစာ',
        inventoryReport: 'စတော့ အစီရင်ခံစာ',
        expenseReport: 'ကုန်ကျစရိတ် အစီရင်ခံစာ',
        workerPaymentReport: 'အလုပ်သမား အခကြေးငွေ အစီရင်ခံစာ',
        date: 'နေ့စွဲ',
        branch: 'ခုခံ',
        period: 'ကာလ',
        totalSales: 'စုစုပေါင်းရောင်းချမှု',
        totalCost: 'စုစုပေါင်းကုန်ကျစရိတ်',
        totalProfit: 'စုစုပေါင်းအမြတ်',
        profitMargin: 'အမြတ်အခွင့်အလမ်း',
        inventory: 'စတော့',
        carats: 'ကာရက်',
        price: 'စျေးနှုန်း',
        quantity: 'အရေအတွက်',
        description: 'အဖြ述်',
        amount: 'ပမာဏ',
        category: 'အမျိုးအစား',
        worker: 'အလုပ်သမား',
        payment: 'အခကြေးငွေ',
        status: 'အခြေအနေ',
        generatedOn: 'ထုတ်လုပ်သည့် နေ့',
        page: 'စာမျက်နှာ',
        of: 'မှ'
      },
      en: {
        title: 'Gemstone Management System',
        salesReport: 'Sales Report',
        profitLossReport: 'Profit & Loss Report',
        inventoryReport: 'Inventory Report',
        expenseReport: 'Expense Report',
        workerPaymentReport: 'Worker Payment Report',
        date: 'Date',
        branch: 'Branch',
        period: 'Period',
        totalSales: 'Total Sales',
        totalCost: 'Total Cost',
        totalProfit: 'Total Profit',
        profitMargin: 'Profit Margin',
        inventory: 'Inventory',
        carats: 'Carats',
        price: 'Price',
        quantity: 'Quantity',
        description: 'Description',
        amount: 'Amount',
        category: 'Category',
        worker: 'Worker',
        payment: 'Payment',
        status: 'Status',
        generatedOn: 'Generated On',
        page: 'Page',
        of: 'of'
      }
    };
  }

  ensureReportsDir() {
    if (!fs.existsSync(this.reportsDir)) {
      fs.mkdirSync(this.reportsDir, { recursive: true });
    }
  }

  /**
   * Generate Daily Sales Report
   */
  async generateDailySalesReport(date, branchId = null, language = 'mm') {
    try {
      const reportId = uuidv4();
      const filename = `daily-sales-${date}-${reportId}.pdf`;
      const filepath = path.join(this.reportsDir, filename);

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
        WHERE DATE(s.sale_date) = ?
      `;

      const params = [date];

      if (branchId) {
        query += ` AND s.branch_id = ?`;
        params.push(branchId);
      }

      query += ` GROUP BY s.id ORDER BY s.sale_date DESC`;

      const [sales] = await db.execute(query, params);

      // Create PDF
      const doc = new PDFDocument();
      doc.pipe(fs.createWriteStream(filepath));

      // Add header
      this.addHeader(doc, this.translations[language].salesReport, language);

      // Add metadata
      doc.fontSize(10).text(`${this.translations[language].date}: ${date}`);
      if (branchId) {
        doc.text(`${this.translations[language].branch}: ${branchId}`);
      }
      doc.text(`${this.translations[language].generatedOn}: ${new Date().toLocaleString()}`);
      doc.moveDown();

      // Add table
      this.addSalesTable(doc, sales, language);

      // Add summary
      const summary = this.calculateSalesSummary(sales);
      this.addSalesSummary(doc, summary, language);

      doc.end();

      // Wait for file to be written
      await new Promise(resolve => doc.on('finish', resolve));

      // Save export record
      await this.recordExport(reportId, 'DAILY_SALES', filename, 'PDF', date, branchId);

      return {
        reportId,
        filename,
        filepath,
        format: 'PDF'
      };
    } catch (error) {
      throw new Error(`Failed to generate daily sales report: ${error.message}`);
    }
  }

  /**
   * Generate Monthly Sales Report
   */
  async generateMonthlySalesReport(yearMonth, branchId = null, language = 'mm') {
    try {
      const reportId = uuidv4();
      const filename = `monthly-sales-${yearMonth}-${reportId}.pdf`;
      const filepath = path.join(this.reportsDir, filename);

      // Get sales data
      let query = `
        SELECT 
          DATE(s.sale_date) as sale_date,
          COUNT(DISTINCT s.id) as sales_count,
          SUM(s.total_stones) as total_stones,
          SUM(s.total_carats) as total_carats,
          SUM(s.total_sale_price) as total_sale_price,
          SUM(si.total_cost) as total_cost,
          SUM(si.profit) as total_profit,
          AVG(si.profit_margin_percentage) as profit_margin
        FROM sales s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        WHERE DATE_FORMAT(s.sale_date, '%Y-%m') = ?
      `;

      const params = [yearMonth];

      if (branchId) {
        query += ` AND s.branch_id = ?`;
        params.push(branchId);
      }

      query += ` GROUP BY DATE(s.sale_date) ORDER BY s.sale_date DESC`;

      const [sales] = await db.execute(query, params);

      // Create PDF
      const doc = new PDFDocument();
      doc.pipe(fs.createWriteStream(filepath));

      // Add header
      this.addHeader(doc, this.translations[language].salesReport, language);

      // Add metadata
      doc.fontSize(10).text(`${this.translations[language].period}: ${yearMonth}`);
      if (branchId) {
        doc.text(`${this.translations[language].branch}: ${branchId}`);
      }
      doc.text(`${this.translations[language].generatedOn}: ${new Date().toLocaleString()}`);
      doc.moveDown();

      // Add table
      this.addMonthlySalesTable(doc, sales, language);

      // Add summary
      const summary = this.calculateSalesSummary(sales);
      this.addSalesSummary(doc, summary, language);

      doc.end();

      await new Promise(resolve => doc.on('finish', resolve));

      await this.recordExport(reportId, 'MONTHLY_SALES', filename, 'PDF', yearMonth, branchId);

      return {
        reportId,
        filename,
        filepath,
        format: 'PDF'
      };
    } catch (error) {
      throw new Error(`Failed to generate monthly sales report: ${error.message}`);
    }
  }

  /**
   * Generate Profit & Loss Report
   */
  async generateProfitLossReport(startDate, endDate, branchId = null, language = 'mm') {
    try {
      const reportId = uuidv4();
      const filename = `profit-loss-${startDate}-${endDate}-${reportId}.pdf`;
      const filepath = path.join(this.reportsDir, filename);

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

      // Create PDF
      const doc = new PDFDocument();
      doc.pipe(fs.createWriteStream(filepath));

      // Add header
      this.addHeader(doc, this.translations[language].profitLossReport, language);

      // Add metadata
      doc.fontSize(10).text(`${this.translations[language].period}: ${startDate} to ${endDate}`);
      if (branchId) {
        doc.text(`${this.translations[language].branch}: ${branchId}`);
      }
      doc.text(`${this.translations[language].generatedOn}: ${new Date().toLocaleString()}`);
      doc.moveDown();

      // Add table
      this.addProfitLossTable(doc, data, language);

      // Add summary
      const summary = this.calculateProfitLossSummary(data);
      this.addProfitLossSummary(doc, summary, language);

      doc.end();

      await new Promise(resolve => doc.on('finish', resolve));

      await this.recordExport(reportId, 'PROFIT_LOSS', filename, 'PDF', `${startDate}-${endDate}`, branchId);

      return {
        reportId,
        filename,
        filepath,
        format: 'PDF'
      };
    } catch (error) {
      throw new Error(`Failed to generate profit/loss report: ${error.message}`);
    }
  }

  /**
   * Generate Inventory Report
   */
  async generateInventoryReport(branchId = null, language = 'mm') {
    try {
      const reportId = uuidv4();
      const filename = `inventory-${reportId}.pdf`;
      const filepath = path.join(this.reportsDir, filename);

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

      // Create PDF
      const doc = new PDFDocument();
      doc.pipe(fs.createWriteStream(filepath));

      // Add header
      this.addHeader(doc, this.translations[language].inventoryReport, language);

      // Add metadata
      if (branchId) {
        doc.fontSize(10).text(`${this.translations[language].branch}: ${branchId}`);
      }
      doc.text(`${this.translations[language].generatedOn}: ${new Date().toLocaleString()}`);
      doc.moveDown();

      // Add table
      this.addInventoryTable(doc, inventory, language);

      // Add summary
      const summary = this.calculateInventorySummary(inventory);
      this.addInventorySummary(doc, summary, language);

      doc.end();

      await new Promise(resolve => doc.on('finish', resolve));

      await this.recordExport(reportId, 'INVENTORY', filename, 'PDF', new Date().toISOString().split('T')[0], branchId);

      return {
        reportId,
        filename,
        filepath,
        format: 'PDF'
      };
    } catch (error) {
      throw new Error(`Failed to generate inventory report: ${error.message}`);
    }
  }

  /**
   * Generate Expense Report
   */
  async generateExpenseReport(startDate, endDate, branchId = null, language = 'mm') {
    try {
      const reportId = uuidv4();
      const filename = `expenses-${startDate}-${endDate}-${reportId}.pdf`;
      const filepath = path.join(this.reportsDir, filename);

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

      // Create PDF
      const doc = new PDFDocument();
      doc.pipe(fs.createWriteStream(filepath));

      // Add header
      this.addHeader(doc, this.translations[language].expenseReport, language);

      // Add metadata
      doc.fontSize(10).text(`${this.translations[language].period}: ${startDate} to ${endDate}`);
      if (branchId) {
        doc.text(`${this.translations[language].branch}: ${branchId}`);
      }
      doc.text(`${this.translations[language].generatedOn}: ${new Date().toLocaleString()}`);
      doc.moveDown();

      // Add table
      this.addExpenseTable(doc, expenses, language);

      // Add summary
      const summary = this.calculateExpenseSummary(expenses);
      this.addExpenseSummary(doc, summary, language);

      doc.end();

      await new Promise(resolve => doc.on('finish', resolve));

      await this.recordExport(reportId, 'EXPENSE', filename, 'PDF', `${startDate}-${endDate}`, branchId);

      return {
        reportId,
        filename,
        filepath,
        format: 'PDF'
      };
    } catch (error) {
      throw new Error(`Failed to generate expense report: ${error.message}`);
    }
  }

  /**
   * Add header to PDF
   */
  addHeader(doc, title, language) {
    doc.fontSize(20).font('Helvetica-Bold').text(this.translations[language].title, { align: 'center' });
    doc.fontSize(16).text(title, { align: 'center' });
    doc.moveDown();
  }

  /**
   * Add sales table to PDF
   */
  addSalesTable(doc, sales, language) {
    const headers = [
      this.translations[language].date,
      this.translations[language].quantity,
      this.translations[language].carats,
      this.translations[language].totalSales,
      this.translations[language].totalCost,
      this.translations[language].totalProfit
    ];

    doc.fontSize(10);
    const startY = doc.y;
    const columnWidth = 90;
    const rowHeight = 20;

    // Draw headers
    headers.forEach((header, i) => {
      doc.text(header, startY + 5, 50 + i * columnWidth, { width: columnWidth - 5 });
    });

    // Draw rows
    sales.forEach((sale, index) => {
      const y = startY + 30 + index * rowHeight;
      doc.text(sale.sale_date, y, 50);
      doc.text(sale.total_stones.toString(), y, 50 + columnWidth);
      doc.text(sale.total_carats.toFixed(2), y, 50 + 2 * columnWidth);
      doc.text(sale.total_sale_price.toFixed(2), y, 50 + 3 * columnWidth);
      doc.text((sale.total_cost || 0).toFixed(2), y, 50 + 4 * columnWidth);
      doc.text((sale.total_profit || 0).toFixed(2), y, 50 + 5 * columnWidth);
    });

    doc.moveDown(sales.length + 2);
  }

  /**
   * Add monthly sales table to PDF
   */
  addMonthlySalesTable(doc, sales, language) {
    // Similar to addSalesTable but with daily aggregation
    this.addSalesTable(doc, sales, language);
  }

  /**
   * Add profit/loss table to PDF
   */
  addProfitLossTable(doc, data, language) {
    const headers = [
      this.translations[language].date,
      this.translations[language].totalSales,
      this.translations[language].totalCost,
      this.translations[language].totalProfit,
      'Expenses'
    ];

    doc.fontSize(10);
    const startY = doc.y;
    const columnWidth = 90;
    const rowHeight = 20;

    // Draw headers
    headers.forEach((header, i) => {
      doc.text(header, startY + 5, 50 + i * columnWidth, { width: columnWidth - 5 });
    });

    // Draw rows
    data.forEach((row, index) => {
      const y = startY + 30 + index * rowHeight;
      doc.text(row.date, y, 50);
      doc.text((row.total_revenue || 0).toFixed(2), y, 50 + columnWidth);
      doc.text((row.total_cost || 0).toFixed(2), y, 50 + 2 * columnWidth);
      doc.text((row.total_profit || 0).toFixed(2), y, 50 + 3 * columnWidth);
      doc.text((row.total_expenses || 0).toFixed(2), y, 50 + 4 * columnWidth);
    });

    doc.moveDown(data.length + 2);
  }

  /**
   * Add inventory table to PDF
   */
  addInventoryTable(doc, inventory, language) {
    const headers = [
      this.translations[language].description,
      this.translations[language].carats,
      this.translations[language].price,
      this.translations[language].status
    ];

    doc.fontSize(10);
    const startY = doc.y;
    const columnWidth = 120;
    const rowHeight = 20;

    // Draw headers
    headers.forEach((header, i) => {
      doc.text(header, startY + 5, 50 + i * columnWidth, { width: columnWidth - 5 });
    });

    // Draw rows
    inventory.forEach((item, index) => {
      const y = startY + 30 + index * rowHeight;
      doc.text(item.name || item.type, y, 50, { width: columnWidth - 5 });
      doc.text(item.carat_weight.toFixed(2), y, 50 + columnWidth);
      doc.text(item.cost_basis.toFixed(2), y, 50 + 2 * columnWidth);
      doc.text(item.status, y, 50 + 3 * columnWidth);
    });

    doc.moveDown(inventory.length + 2);
  }

  /**
   * Add expense table to PDF
   */
  addExpenseTable(doc, expenses, language) {
    const headers = [
      this.translations[language].date,
      this.translations[language].category,
      this.translations[language].description,
      this.translations[language].amount,
      this.translations[language].status
    ];

    doc.fontSize(10);
    const startY = doc.y;
    const columnWidth = 100;
    const rowHeight = 20;

    // Draw headers
    headers.forEach((header, i) => {
      doc.text(header, startY + 5, 50 + i * columnWidth, { width: columnWidth - 5 });
    });

    // Draw rows
    expenses.forEach((expense, index) => {
      const y = startY + 30 + index * rowHeight;
      doc.text(expense.expense_date, y, 50);
      doc.text(expense.category, y, 50 + columnWidth);
      doc.text(expense.description || '', y, 50 + 2 * columnWidth, { width: columnWidth - 5 });
      doc.text(expense.amount.toFixed(2), y, 50 + 3 * columnWidth);
      doc.text(expense.status, y, 50 + 4 * columnWidth);
    });

    doc.moveDown(expenses.length + 2);
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
    const byCategory = {};
    expenses.forEach(exp => {
      if (!byCategory[exp.category]) {
        byCategory[exp.category] = 0;
      }
      byCategory[exp.category] += exp.amount;
    });

    return {
      totalExpenses: expenses.reduce((sum, e) => sum + (e.amount || 0), 0),
      expenseCount: expenses.length,
      byCategory
    };
  }

  /**
   * Add summary section to PDF
   */
  addSalesSummary(doc, summary, language) {
    doc.fontSize(12).font('Helvetica-Bold').text(`${this.translations[language].totalSales}: ${summary.totalRevenue.toFixed(2)}`, { underline: true });
    doc.fontSize(10).font('Helvetica').text(`${this.translations[language].totalCost}: ${summary.totalCost.toFixed(2)}`);
    doc.text(`${this.translations[language].totalProfit}: ${summary.totalProfit.toFixed(2)}`);
    doc.text(`${this.translations[language].profitMargin}: ${summary.avgProfitMargin.toFixed(2)}%`);
  }

  addProfitLossSummary(doc, summary, language) {
    doc.fontSize(12).font('Helvetica-Bold').text(`${this.translations[language].totalSales}: ${summary.totalRevenue.toFixed(2)}`, { underline: true });
    doc.fontSize(10).font('Helvetica').text(`${this.translations[language].totalCost}: ${summary.totalCost.toFixed(2)}`);
    doc.text(`${this.translations[language].totalProfit}: ${summary.totalProfit.toFixed(2)}`);
    doc.text(`Expenses: ${summary.totalExpenses.toFixed(2)}`);
    doc.text(`Net Profit: ${summary.netProfit.toFixed(2)}`);
  }

  addInventorySummary(doc, summary, language) {
    doc.fontSize(12).font('Helvetica-Bold').text(`${this.translations[language].inventory}: ${summary.totalStones} ${this.translations[language].quantity}`, { underline: true });
    doc.fontSize(10).font('Helvetica').text(`${this.translations[language].carats}: ${summary.totalCarats.toFixed(2)}`);
    doc.text(`${this.translations[language].price}: ${summary.totalValue.toFixed(2)}`);
  }

  addExpenseSummary(doc, summary, language) {
    doc.fontSize(12).font('Helvetica-Bold').text(`${this.translations[language].totalSales}: ${summary.totalExpenses.toFixed(2)}`, { underline: true });
    doc.fontSize(10).font('Helvetica').text(`${this.translations[language].quantity}: ${summary.expenseCount}`);
  }

  /**
   * Record export action
   */
  async recordExport(reportId, reportType, filename, format, period, branchId) {
    try {
      const query = `
        INSERT INTO export_logs (
          id, report_type, filename, format, period, branch_id, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, NOW())
      `;

      await db.execute(query, [reportId, reportType, filename, format, period, branchId]);
    } catch (error) {
      console.error('Failed to record export:', error);
    }
  }
}

module.exports = new PDFReportGenerator();
