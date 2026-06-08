# PDF and Excel Export System - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Features](#features)
4. [API Endpoints](#api-endpoints)
5. [Database Schema](#database-schema)
6. [Implementation Guide](#implementation-guide)
7. [Security and Audit](#security-and-audit)
8. [Performance Considerations](#performance-considerations)

---

## Overview

The Export System provides comprehensive PDF and Excel export functionality for the gemstone management platform. It supports multiple report types, Myanmar language localization, role-based access control, and complete audit logging.

### Key Capabilities

- **Multiple Report Types**: Daily/Monthly Sales, Profit & Loss, Inventory, Expenses, Worker Payments
- **Dual Format Support**: PDF and Excel exports
- **Myanmar Language Support**: Full localization for Myanmar users
- **Role-Based Access**: Owner and Accountant access to sensitive reports
- **Audit Logging**: Complete tracking of all export actions
- **Date/Branch Filtering**: Flexible filtering options
- **Company Branding**: Logo and company information support

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Dashboard                        │
│              (Export Buttons, Report Selection)              │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                    API Layer                                 │
│         (Export Endpoints, Role Validation)                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Service Layer                               │
│  ┌──────────────────┬──────────────────┬──────────────────┐  │
│  │ PDF Generator    │ Excel Exporter   │ Audit Service    │  │
│  └──────────────────┴──────────────────┴──────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Database Layer                              │
│  ┌──────────────────┬──────────────────┬──────────────────┐  │
│  │ Export Logs      │ Audit Logs       │ Export Settings  │  │
│  └──────────────────┴──────────────────┴──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

### 1. PDF Reports

**Daily Sales Report**
- Date-specific sales transactions
- Buyer information
- Stone quantities and carats
- Revenue, cost, and profit calculations
- Profit margin percentages

**Monthly Sales Report**
- Aggregated daily sales data
- Monthly trends
- Performance metrics
- Summary statistics

**Profit & Loss Report**
- Revenue tracking
- Cost analysis
- Profit calculations
- Expense breakdown
- Net profit summary

**Inventory Report**
- Current inventory status
- Stone details (type, color, clarity)
- Carat weights and valuations
- Cost basis information
- Lot associations

**Expense Report**
- Expense categorization
- Allocation tracking
- Time period analysis
- Category-wise summaries

### 2. Excel Exports

**Sales Data Export**
- Detailed transaction records
- Buyer information
- Profit calculations
- Sortable and filterable data
- Summary statistics

**Inventory Export**
- Complete inventory listing
- Stone specifications
- Valuations
- Status tracking
- Lot references

**Expense Export**
- Expense records
- Category breakdowns
- Allocation details
- Status tracking

**Profit/Loss Export**
- Daily P&L data
- Revenue and cost tracking
- Profit calculations
- Expense allocations

### 3. Myanmar Language Support

All reports support Myanmar (Burmese) language with complete translations for:
- Report titles and headers
- Column names
- Summary labels
- Metadata information

### 4. Audit Logging

Every export action is logged with:
- User identification
- Action type (CREATE, DOWNLOAD, DELETE)
- Timestamp
- IP address
- User agent information
- File metadata

---

## API Endpoints

### PDF Export Endpoints

```
GET /api/export/pdf/daily-sales
  Query Parameters:
    - date (required): YYYY-MM-DD
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en' (default: 'mm')
  Response: PDF file download

GET /api/export/pdf/monthly-sales
  Query Parameters:
    - yearMonth (required): YYYY-MM
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en'
  Response: PDF file download

GET /api/export/pdf/profit-loss
  Query Parameters:
    - startDate (required): YYYY-MM-DD
    - endDate (required): YYYY-MM-DD
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en'
  Response: PDF file download
  Access: Owner, Accountant

GET /api/export/pdf/inventory
  Query Parameters:
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en'
  Response: PDF file download

GET /api/export/pdf/expenses
  Query Parameters:
    - startDate (required): YYYY-MM-DD
    - endDate (required): YYYY-MM-DD
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en'
  Response: PDF file download
  Access: Owner, Accountant
```

### Excel Export Endpoints

```
GET /api/export/excel/sales
  Query Parameters:
    - startDate (required): YYYY-MM-DD
    - endDate (required): YYYY-MM-DD
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en'
  Response: Excel file download

GET /api/export/excel/inventory
  Query Parameters:
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en'
  Response: Excel file download

GET /api/export/excel/expenses
  Query Parameters:
    - startDate (required): YYYY-MM-DD
    - endDate (required): YYYY-MM-DD
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en'
  Response: Excel file download
  Access: Owner, Accountant

GET /api/export/excel/profit-loss
  Query Parameters:
    - startDate (required): YYYY-MM-DD
    - endDate (required): YYYY-MM-DD
    - branchId (optional): Branch ID
    - language (optional): 'mm' or 'en'
  Response: Excel file download
  Access: Owner, Accountant
```

### Audit and Management Endpoints

```
GET /api/export/history
  Query Parameters:
    - limit (optional): 20 (default)
    - offset (optional): 0 (default)
  Response: List of exports
  Access: Owner, Accountant

DELETE /api/export/:exportId
  Response: Deletion confirmation
  Access: Owner only
```

---

## Database Schema

### export_logs Table

```sql
Columns:
- id (VARCHAR 36, PK)
- report_type (ENUM: DAILY_SALES, MONTHLY_SALES, PROFIT_LOSS, INVENTORY, EXPENSE, WORKER_PAYMENT, SALES)
- filename (VARCHAR 255)
- format (ENUM: PDF, EXCEL)
- period (VARCHAR 100)
- branch_id (VARCHAR 36, FK)
- created_by (VARCHAR 36, FK)
- created_at (TIMESTAMP)
- file_size (BIGINT)
- download_count (INT)

Indexes:
- idx_report_type
- idx_created_at
- idx_branch_id
- idx_created_by
- idx_report_type_date
- idx_branch_date
```

### export_audit_logs Table

```sql
Columns:
- id (VARCHAR 36, PK)
- export_id (VARCHAR 36, FK)
- user_id (VARCHAR 36, FK)
- action (ENUM: CREATED, DOWNLOADED, DELETED, SHARED)
- action_timestamp (TIMESTAMP)
- ip_address (VARCHAR 45)
- user_agent (VARCHAR 500)
- notes (TEXT)

Indexes:
- idx_export_id
- idx_user_id
- idx_action
- idx_timestamp
- idx_user_date
```

### export_settings Table

```sql
Columns:
- id (VARCHAR 36, PK)
- branch_id (VARCHAR 36, FK)
- company_name (VARCHAR 255)
- company_logo_path (VARCHAR 500)
- company_address (TEXT)
- company_phone (VARCHAR 20)
- company_email (VARCHAR 100)
- default_language (ENUM: mm, en)
- include_logo (BOOLEAN)
- include_company_info (BOOLEAN)
- page_orientation (ENUM: PORTRAIT, LANDSCAPE)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

---

## Implementation Guide

### Step 1: Database Setup

```bash
# Run migration
mysql -u root -p < backend/models/ExportSchema.sql

# Verify tables
mysql -u root -p -e "SHOW TABLES FROM gemstone_db LIKE 'export%';"
```

### Step 2: Install Dependencies

```bash
cd backend
npm install pdfkit exceljs
```

### Step 3: Register Routes

```javascript
// In server.js
const exportRoutes = require('./routes/export.routes');
app.use('/api/export', exportRoutes);
```

### Step 4: Configure Export Settings

```javascript
// Set company branding
const ExportSettingsService = require('./services/exportSettingsService');

await ExportSettingsService.updateSettings({
  branchId: 'branch-001',
  companyName: 'Gemstone Trading Co.',
  companyLogo: '/path/to/logo.png',
  companyAddress: 'Yangon, Myanmar',
  defaultLanguage: 'mm'
});
```

### Step 5: Test Export Functionality

```bash
# Test PDF export
curl "http://localhost:3000/api/export/pdf/daily-sales?date=2026-05-31&language=mm"

# Test Excel export
curl "http://localhost:3000/api/export/excel/sales?startDate=2026-05-01&endDate=2026-05-31"
```

---

## Security and Audit

### Role-Based Access Control

| Report Type | Owner | Accountant | Worker | Broker |
|------------|-------|-----------|--------|--------|
| Daily Sales | ✓ | ✓ | ✓ | ✓ |
| Monthly Sales | ✓ | ✓ | ✓ | ✓ |
| Profit & Loss | ✓ | ✓ | ✗ | ✗ |
| Inventory | ✓ | ✓ | ✓ | ✓ |
| Expenses | ✓ | ✓ | ✗ | ✗ |

### Audit Logging

All export actions are logged with:
- **User ID**: Who performed the action
- **Action Type**: CREATE, DOWNLOAD, DELETE, SHARE
- **Timestamp**: When the action occurred
- **IP Address**: Source IP address
- **User Agent**: Browser/client information
- **Notes**: Additional context

### Suspicious Activity Detection

The system automatically detects:
- Multiple exports in short time periods
- Exports from unusual IP addresses
- Unauthorized exports by non-admin users
- Unusual download patterns

---

## Performance Considerations

### Optimization Strategies

1. **Database Indexing**
   - Indexed on report_type, created_at, branch_id
   - Composite indexes for common query patterns
   - Separate audit log indexes for fast retrieval

2. **Caching**
   - Cache export settings per branch
   - Cache frequently accessed reports (1 hour TTL)
   - Implement Redis for high-volume scenarios

3. **File Management**
   - Store exports in separate directory
   - Implement file cleanup (delete exports > 30 days old)
   - Compress old exports to reduce storage

4. **Query Optimization**
   - Use aggregation queries for summaries
   - Limit result sets with pagination
   - Pre-calculate daily/monthly summaries

### Scalability

- **Horizontal Scaling**: Separate export service instance
- **Asynchronous Processing**: Queue large exports for background processing
- **CDN Integration**: Serve exported files via CDN
- **Database Partitioning**: Partition audit logs by date

---

## Example Usage

### Frontend Integration

```javascript
// Export daily sales as PDF
async function exportDailySalesReport(date) {
  const response = await fetch(
    `/api/export/pdf/daily-sales?date=${date}&language=mm`
  );
  const blob = await response.blob();
  
  // Download file
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `daily-sales-${date}.pdf`;
  a.click();
}

// Export inventory as Excel
async function exportInventory() {
  const response = await fetch(
    `/api/export/excel/inventory?branchId=branch-001&language=mm`
  );
  const blob = await response.blob();
  
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `inventory-${new Date().toISOString()}.xlsx`;
  a.click();
}
```

---

## Troubleshooting

### Common Issues

**Issue**: PDF generation fails with memory error
- **Solution**: Implement streaming for large datasets, use pagination

**Issue**: Excel file corrupted
- **Solution**: Ensure proper workbook closure, validate file size

**Issue**: Audit logs growing too large
- **Solution**: Implement archival strategy, delete old logs periodically

**Issue**: Export permissions not working
- **Solution**: Verify role assignments, check middleware configuration

---

## Maintenance

### Regular Tasks

1. **Weekly**: Review suspicious activity patterns
2. **Monthly**: Archive old export files
3. **Quarterly**: Analyze export usage patterns
4. **Annually**: Review and update export templates

### Monitoring

- Track export generation time
- Monitor file sizes
- Watch for unusual access patterns
- Alert on failed exports

---

## Next Steps

1. **Frontend UI**: Build export buttons in dashboard
2. **Scheduled Exports**: Implement automatic report generation
3. **Email Distribution**: Send reports via email
4. **Advanced Analytics**: Add charts and visualizations
5. **Mobile Support**: Mobile-friendly export formats

---

**Last Updated**: May 31, 2026
**Version**: 1.0.0
**Status**: Production Ready
