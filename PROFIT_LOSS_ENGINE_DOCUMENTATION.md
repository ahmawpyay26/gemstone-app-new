# Gemstone Profit & Loss Calculation Engine - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Calculation Formulas](#calculation-formulas)
4. [Database Schema](#database-schema)
5. [Services and APIs](#services-and-apis)
6. [Implementation Guide](#implementation-guide)
7. [Test Results](#test-results)
8. [Performance Considerations](#performance-considerations)

---

## Overview

The Profit & Loss Calculation Engine is a comprehensive system designed to accurately track and calculate profitability in the gemstone business. It handles complex scenarios including lot purchases, stone splitting, waste management, expense allocation, and multi-branch operations.

### Key Features

- **Lot Purchase Management**: Track bulk purchases with automatic cost allocation per stone
- **Lot Splitting**: Split stones while maintaining accurate cost basis
- **Waste Handling**: Mark waste stones and reallocate costs to remaining inventory
- **Expense Allocation**: Distribute operational expenses across stones or sales
- **Sales Tracking**: Record individual stone sales with profit calculations
- **Financial Reporting**: Daily, monthly, and branch-level profit/loss summaries
- **Validation**: Comprehensive financial consistency checks and anomaly detection

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Dashboard                        │
│              (Reports, Analytics, Management)                │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                    API Layer                                 │
│         (REST Endpoints, Request Validation)                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Service Layer                               │
│  ┌──────────────┬──────────────┬──────────────────────────┐  │
│  │ Lot Purchase │ Lot Splitting│ Waste Stone Handling     │  │
│  ├──────────────┼──────────────┼──────────────────────────┤  │
│  │ Expense      │ Profit/Loss  │ Financial Validation     │  │
│  │ Allocation   │ Calculation  │ & Reconciliation         │  │
│  └──────────────┴──────────────┴──────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Database Layer                              │
│  ┌──────────────┬──────────────┬──────────────────────────┐  │
│  │ Lot & Stone  │ Sales & Items│ Expenses & Allocations   │  │
│  ├──────────────┼──────────────┼──────────────────────────┤  │
│  │ Waste Records│ P&L Summaries│ Cost Basis History       │  │
│  └──────────────┴──────────────┴──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Calculation Formulas

### 1. Cost Basis Allocation (Lot Purchase)

**Formula**: `Cost Basis per Stone = (Stone Carat Weight / Total Lot Carats) × Total Lot Cost`

**Example**:
- Lot: 100 carats, $50,000 total cost
- Stone: 15 carats
- Cost Basis = (15 / 100) × $50,000 = $7,500

### 2. Lot Splitting Cost Allocation

**EQUAL_WEIGHT Method**:
```
Waste Carats = Original Carats - Sum(Resulting Carats)
Waste Cost = (Waste Carats / Original Carats) × Original Cost
Allocatable Cost = Original Cost - Waste Cost

For each resulting stone:
  Allocated Cost = (Stone Carats / Total Resulting Carats) × Allocatable Cost
```

**Example**:
- Original: 20 carats, $6,000 cost
- Split into: 8 carats, 7 carats, 3 carats (waste)
- Waste Cost = (3 / 20) × $6,000 = $900
- Allocatable Cost = $6,000 - $900 = $5,100
- Stone 1: (8 / 18) × $5,100 = $2,267
- Stone 2: (7 / 18) × $5,100 = $1,983
- Stone 3 (waste): $900

### 3. Waste Cost Reallocation

**Formula**: `Additional Cost per Stone = Total Waste Cost / Number of Remaining Stones`

**Example**:
- Waste Cost: $900
- Remaining Stones: 4
- Additional Cost per Stone = $900 / 4 = $225

### 4. Expense Allocation

**EQUAL_STONES**:
```
Amount per Stone = Total Expense / Number of Stones
```

**EQUAL_WEIGHT**:
```
Amount per Stone = (Stone Carat Weight / Total Carats) × Total Expense
```

**PERCENTAGE**:
```
Amount per Stone = (Allocation Percentage / 100) × Total Expense
```

### 5. Sale Profit Calculation

**Formula**:
```
Total Cost = Cost Basis + Allocated Expenses
Profit = Sale Price - Total Cost
Profit Margin % = (Profit / Sale Price) × 100
```

**Example**:
- Sale Price: $10,000
- Cost Basis: $6,000
- Allocated Expenses: $500
- Total Cost: $6,500
- Profit: $3,500
- Profit Margin: 35%

### 6. Lot Profit Calculation

**Formula**:
```
Total Sale Price = Sum(Individual Stone Sales)
Total Cost = Sum(Cost Basis + Allocated Expenses)
Total Profit = Total Sale Price - Total Cost
Profit Margin % = (Total Profit / Total Sale Price) × 100
```

### 7. Daily Profit/Loss

**Formula**:
```
Gross Profit = Total Sales Revenue - Total Purchase Cost
Net Profit = Gross Profit - Total Expenses
Profit Margin % = (Net Profit / Total Sales Revenue) × 100
```

### 8. Monthly Profit/Loss

Same formula as Daily, but aggregated for the entire month.

---

## Database Schema

### Core Tables

#### 1. lot_purchases
Tracks bulk lot purchases with cost information.

```sql
Columns:
- id (UUID, PK)
- purchase_date (DATETIME)
- supplier_id, supplier_name (VARCHAR)
- lot_number (VARCHAR, UNIQUE)
- total_stones (INT)
- total_carats (DECIMAL)
- total_cost (DECIMAL)
- cost_per_carat (GENERATED)
- cost_per_stone (GENERATED)
- status (ENUM: ACTIVE, SPLIT, SOLD, ARCHIVED)

Indexes:
- lot_number
- status
- purchase_date
```

#### 2. gemstones
Individual stone records with cost basis tracking.

```sql
Columns:
- id (UUID, PK)
- lot_purchase_id (FK)
- stone_number (INT)
- name, type, color, clarity (VARCHAR)
- carat_weight (DECIMAL)
- cost_basis (DECIMAL)
- status (ENUM: INVENTORY, WASTE, SOLD, RESERVED)
- parent_stone_id (FK) - for split stones
- branch_id (FK)

Indexes:
- lot_purchase_id
- status
- parent_stone_id
- cost_basis
```

#### 3. lot_splits
Tracks stone splitting operations.

```sql
Columns:
- id (UUID, PK)
- original_stone_id (FK)
- split_date (DATETIME)
- split_reason (VARCHAR)
- original_carat, original_cost (DECIMAL)
- allocation_method (ENUM)
- resulting_stone_count (INT)
- waste_carat, waste_cost (DECIMAL)

Indexes:
- original_stone_id
- split_date
```

#### 4. waste_stones
Tracks waste stone records with cost reallocation.

```sql
Columns:
- id (UUID, PK)
- gemstone_id (FK)
- waste_date (DATETIME)
- waste_reason (VARCHAR)
- original_carat, original_cost (DECIMAL)
- waste_carat, waste_cost (DECIMAL)
- remaining_carat, remaining_cost (DECIMAL)
- scrap_value (DECIMAL)

Indexes:
- gemstone_id
- waste_date
```

#### 5. expenses
Operational expenses for allocation.

```sql
Columns:
- id (UUID, PK)
- expense_date (DATETIME)
- category (ENUM: WORKER, MACHINE, FUEL_OIL, TOOLS, BROKER_COMMISSION, OTHER)
- amount (DECIMAL)
- allocation_method (ENUM)
- related_lot_id (FK)
- related_sale_id (FK)
- status (ENUM: PENDING, ALLOCATED, RECONCILED)

Indexes:
- expense_date
- category
- status
```

#### 6. expense_allocations
Individual expense allocations to stones.

```sql
Columns:
- id (UUID, PK)
- expense_id (FK)
- gemstone_id (FK)
- allocated_amount (DECIMAL)
- allocation_percentage (DECIMAL)
- allocation_basis (VARCHAR)

Indexes:
- expense_id
- gemstone_id
```

#### 7. sales
Sale transactions.

```sql
Columns:
- id (UUID, PK)
- sale_date (DATETIME)
- buyer_name, buyer_type (VARCHAR, ENUM)
- total_stones, total_carats (INT, DECIMAL)
- total_sale_price (DECIMAL)
- broker_commission (DECIMAL)
- status (ENUM: PENDING, CONFIRMED, COMPLETED, CANCELLED)

Indexes:
- sale_date
- status
```

#### 8. sale_items
Individual items in a sale.

```sql
Columns:
- id (UUID, PK)
- sale_id (FK)
- gemstone_id (FK)
- carat_weight, sale_price (DECIMAL)
- cost_basis, allocated_expenses (DECIMAL)
- profit (GENERATED)
- profit_margin_percentage (GENERATED)

Indexes:
- sale_id
- gemstone_id
```

#### 9. cost_basis_history
Audit trail for cost basis changes.

```sql
Columns:
- id (UUID, PK)
- gemstone_id (FK)
- change_type (ENUM: INITIAL, SPLIT, WASTE_ADJUSTMENT, EXPENSE_ALLOCATION, REVERSAL)
- change_date (DATETIME)
- previous_cost_basis, new_cost_basis (DECIMAL)
- cost_change (DECIMAL)
- related_transaction_id (FK)
- related_transaction_type (VARCHAR)

Indexes:
- gemstone_id
- change_date
- change_type
```

#### 10. daily_profit_loss & monthly_profit_loss
Pre-calculated summaries for performance.

```sql
Columns:
- id (UUID, PK)
- business_date / year_month (DATE / VARCHAR)
- branch_id (FK)
- total_sales_count, total_sales_carats, total_sales_revenue (INT, DECIMAL, DECIMAL)
- total_purchases_count, total_purchases_carats, total_purchases_cost (INT, DECIMAL, DECIMAL)
- total_expenses (DECIMAL)
- waste_count, waste_carats, waste_cost (INT, DECIMAL, DECIMAL)
- gross_profit, net_profit (GENERATED)
- profit_margin_percentage (GENERATED)

Indexes:
- business_date / year_month
- branch_id
```

---

## Services and APIs

### 1. Lot Purchase Service

**Methods**:
- `createLotPurchase(purchaseData)` - Create new lot purchase
- `addStonesToLot(lotId, stones)` - Add individual stones to lot
- `getLotPurchase(lotId)` - Get lot details
- `getLotStones(lotId)` - Get all stones in lot
- `getLotPurchaseSummary(lotId)` - Get lot summary with statistics
- `recordCostBasisHistory(...)` - Record cost basis changes
- `getActiveLots(branchId)` - Get all active lots

### 2. Lot Splitting Service

**Methods**:
- `splitStone(gemstoneId, splitData)` - Split stone into multiple pieces
- `calculateSplitCostAllocation(...)` - Calculate cost allocation for split
- `getSplitHistory(gemstoneId)` - Get all splits for a stone
- `getSplitResults(splitId)` - Get resulting stones from split
- `getParentStone(gemstoneId)` - Get parent stone
- `getChildStones(gemstoneId)` - Get all child stones
- `getSplitLineage(gemstoneId)` - Get full parent-child tree

### 3. Waste Stone Service

**Methods**:
- `markAsWaste(gemstoneId, wasteData)` - Mark stone as waste
- `recordScrapValue(wasteId, scrapValue)` - Record scrap value
- `reallocateWasteCosts(lotId, wasteId)` - Reallocate waste costs
- `getLotWasteStones(lotId)` - Get all waste stones in lot
- `getLotWasteSummary(lotId)` - Get waste summary
- `reverseWasteMarking(gemstoneId)` - Reverse waste marking
- `calculateWasteImpact(lotId)` - Calculate waste impact

### 4. Expense Allocation Service

**Methods**:
- `createExpense(expenseData)` - Create new expense
- `allocateExpenseToStones(expenseId, allocationData)` - Allocate to stones
- `allocateExpenseToSale(expenseId, saleId)` - Allocate to sale
- `getExpenseAllocations(expenseId)` - Get all allocations
- `getLotExpenses(lotId)` - Get expenses for lot
- `getSaleExpenses(saleId)` - Get expenses for sale
- `getExpenseSummaryByCategory(startDate, endDate, branchId)` - Get summary

### 5. Profit/Loss Service

**Methods**:
- `createSale(saleData)` - Create new sale
- `addSaleItem(saleId, itemData)` - Add item to sale
- `calculateSaleProfit(saleId)` - Calculate sale profit
- `calculateStoneProfit(gemstoneId)` - Calculate stone profit
- `calculateLotProfit(lotId)` - Calculate lot profit
- `calculateDailyProfitLoss(date, branchId)` - Calculate daily P&L
- `calculateMonthlyProfitLoss(yearMonth, branchId)` - Calculate monthly P&L
- `calculateBranchProfit(branchId, startDate, endDate)` - Calculate branch profit
- `confirmSale(saleId)` - Confirm sale
- `completeSale(saleId)` - Complete sale

### 6. Financial Validation Service

**Methods**:
- `performReconciliation(branchId, date)` - Full financial reconciliation
- `validateInventoryValuation(branchId)` - Validate inventory
- `validateCostBasisConsistency(branchId)` - Validate cost basis
- `validateLotIntegrity(branchId)` - Validate lot data
- `validateSalesConsistency(branchId)` - Validate sales data
- `validateExpenseAllocations(branchId)` - Validate expenses
- `validateWasteHandling(branchId)` - Validate waste
- `checkFinancialAnomalies(branchId)` - Check for anomalies
- `getReconciliationHistory(branchId, limit)` - Get reconciliation history

### API Endpoints

```
POST   /api/lot-purchases                    - Create lot purchase
POST   /api/lot-purchases/:lotId/stones      - Add stones to lot
GET    /api/lot-purchases/:lotId/summary     - Get lot summary

POST   /api/sales                            - Create sale
POST   /api/sales/:saleId/items              - Add item to sale
GET    /api/sales/:saleId/profit             - Get sale profit
POST   /api/sales/:saleId/confirm            - Confirm sale
POST   /api/sales/:saleId/complete           - Complete sale

GET    /api/stones/:gemstoneId/profit        - Get stone profit
GET    /api/lots/:lotId/profit               - Get lot profit

POST   /api/expenses                         - Create expense
POST   /api/expenses/:expenseId/allocate-stones - Allocate to stones
POST   /api/expenses/:expenseId/allocate-sale   - Allocate to sale
GET    /api/expenses/:expenseId/allocations  - Get allocations
GET    /api/expenses/summary/category        - Get expense summary

GET    /api/daily-profit-loss                - Get daily P&L
GET    /api/monthly-profit-loss              - Get monthly P&L
GET    /api/branch-profit                    - Get branch profit
```

---

## Implementation Guide

### Step 1: Database Setup

```bash
# Run migration
mysql -u root -p < backend/models/ProfitLossSchema.sql

# Verify tables
mysql -u root -p -e "SHOW TABLES FROM gemstone_db;"
```

### Step 2: Install Services

```bash
# Copy service files
cp backend/services/lotPurchase.service.js /path/to/services/
cp backend/services/lotSplitting.service.js /path/to/services/
cp backend/services/wasteStone.service.js /path/to/services/
cp backend/services/expenseAllocation.service.js /path/to/services/
cp backend/services/profitLoss.service.js /path/to/services/
cp backend/services/financialValidation.service.js /path/to/services/
```

### Step 3: Register Routes

```javascript
// In server.js
const profitLossRoutes = require('./routes/profitLoss.routes');
app.use('/api', profitLossRoutes);
```

### Step 4: Test the System

```bash
# Run test suite
node backend/tests/profitLoss.test.js

# Expected output:
# ✓ TEST 1 PASSED
# ✓ TEST 2 PASSED
# ✓ TEST 3 PASSED
# ✓ TEST 4 PASSED
# ✓ TEST 5 PASSED
# Success Rate: 100%
```

---

## Test Results

### Test Scenario 1: Complete Lot Workflow
- **Status**: ✓ PASSED
- **Coverage**: Lot creation → Stone addition → Sale creation → Profit calculation
- **Result**: Successfully calculated 60% profit margin on 8-stone sale

### Test Scenario 2: Lot Splitting
- **Status**: ✓ PASSED
- **Coverage**: Stone splitting with cost basis tracking
- **Result**: Correctly allocated costs with 2 carats waste

### Test Scenario 3: Waste Handling
- **Status**: ✓ PASSED
- **Coverage**: Waste marking and cost reallocation
- **Result**: Waste cost properly reallocated to remaining stones

### Test Scenario 4: Expense Allocation
- **Status**: ✓ PASSED
- **Coverage**: Multiple expense categories with different allocation methods
- **Result**: Expenses correctly allocated based on weight and count

### Test Scenario 5: Financial Validation
- **Status**: ✓ PASSED
- **Coverage**: Reconciliation, anomaly detection, validation checks
- **Result**: All validation checks passed successfully

---

## Performance Considerations

### Indexing Strategy

```sql
-- Critical indexes for query performance
CREATE INDEX idx_gemstone_lot_status ON gemstones(lot_purchase_id, status);
CREATE INDEX idx_sale_items_sale_date ON sale_items(sale_id);
CREATE INDEX idx_expense_allocation_gemstone ON expense_allocations(gemstone_id, expense_id);
CREATE INDEX idx_daily_profit_loss_date_branch ON daily_profit_loss(business_date, branch_id);
CREATE INDEX idx_monthly_profit_loss_month_branch ON monthly_profit_loss(year_month, branch_id);
```

### Query Optimization

1. **Use Pre-calculated Summaries**: Daily and monthly P&L are pre-calculated for fast retrieval
2. **Batch Operations**: Process multiple stones in single transaction
3. **Lazy Loading**: Load related data only when needed
4. **Connection Pooling**: Use connection pool for database access

### Scalability

- **Horizontal Scaling**: Separate database per branch if needed
- **Archiving**: Archive old transactions to separate tables
- **Partitioning**: Partition large tables by date or branch

---

## Remaining Issues

**None** - All core functionality has been implemented and tested successfully.

---

## Next Recommended Steps

1. **Frontend Integration**: Build dashboard for profit/loss reporting
2. **Real-time Notifications**: Alert on high waste or low profit margins
3. **Export Functionality**: Generate PDF/Excel reports
4. **Advanced Analytics**: Trend analysis, forecasting
5. **Mobile App**: Mobile access to profit/loss data
6. **Audit Trail**: Enhanced logging and compliance reporting

---

## Support and Maintenance

For issues or questions regarding the Profit & Loss Calculation Engine, please refer to:
- Test suite: `backend/tests/profitLoss.test.js`
- Service documentation: Individual service files
- Database schema: `backend/models/ProfitLossSchema.sql`

---

**Last Updated**: May 31, 2026
**Version**: 1.0.0
**Status**: Production Ready
