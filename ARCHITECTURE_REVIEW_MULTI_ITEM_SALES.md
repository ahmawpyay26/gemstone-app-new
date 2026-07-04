# Multi-Item Sales Architecture Review

**Base Commit:** 37c0469 (PAT #195 SUCCESS)  
**Review Date:** July 4, 2026  
**Scope:** Direct Sales Page Multi-Item Implementation  
**Status:** Analysis Only - No Code Changes

---

## Executive Summary

The current Gemstone Management system is designed with a **single-item-per-sale** architecture. Implementing multi-item sales requires significant structural changes to data models, business logic, and UI/UX. This review provides a comprehensive analysis of the required changes, risks, and recommended implementation approach.

**Key Finding:** Multi-item sales is **technically feasible** but requires careful planning to maintain backward compatibility and data integrity.

---

## 1. Current Architecture Analysis

### 1.1 Existing Data Models

#### Sale Model (Current - Single Item)
```dart
class Sale {
  String id;
  String gemstoneId;        // Single gemstone reference
  String gemstoneName;
  String? customerId;
  String customerName;
  double amount;            // Total invoice amount
  double costPrice;         // Total COGS
  double commissionFee;     // Total commission
  int quantity;             // Quantity of single item
  double weightCarat;       // Weight of single item
  String paymentMethod;     // cash | bank | credit
  String note;
  int saleDate;
  
  // Transaction history fields
  double netSale;
  double costUsed;
  double remainingCostAfterSale;
  double profitGenerated;
  double accumulatedProfit;
  
  // Soft delete & attachments
  bool isDeleted;
  int? deletedAt;
  String? deletedBy;
  String? deleteReason;
  List<String> photoPaths;
}
```

**Current Limitations:**
- One `gemstoneId` per sale (single item only)
- One `quantity` per sale
- One `costPrice` per sale
- Cannot represent invoice structure with multiple line items
- All transaction history fields assume single-item context

#### Related Models

**Gemstone (Inventory):**
- Tracks purchase quantity, cost, and sales history
- `soldQuantity` and `remainingQuantity` are derived from Sale records
- Cost recovery logic tied to single sale

**Customer:**
- `currentBalance` updated per sale
- Ledger entries created per sale
- No invoice-level grouping

**BrokerSaleRecord (Reference):**
- Single item per record
- Similar single-item structure
- Shows that broker sales also follow single-item pattern

---

## 2. Multi-Item Sales Data Model Design

### 2.1 Proposed New Models

#### Option A: Invoice + LineItem (Recommended)

**Advantages:**
- Clean separation of concerns
- Proper invoice-level grouping
- Supports future features (invoice templates, bulk operations)
- Easier to implement invoice-level operations

**Disadvantages:**
- Requires schema migration
- More complex queries
- Breaking change to existing Sale model

```dart
/// Invoice represents a single customer transaction with multiple items
class Invoice {
  String id;                    // Unique invoice ID
  String? customerId;           // Customer reference
  String customerName;          // For backward compatibility
  String paymentMethod;         // cash | bank | credit
  String invoiceNumber;         // Human-readable invoice number
  
  // Invoice-level totals
  double totalAmount;           // Sum of all line items
  double totalCommission;       // Sum of all commissions
  double totalCost;             // Sum of all COGS
  double netAmount;             // totalAmount - totalCommission
  
  // Metadata
  String note;
  int invoiceDate;              // Unix timestamp
  List<String> photoPaths;      // Invoice-level attachments
  
  // Soft delete
  bool isDeleted;
  int? deletedAt;
  String? deletedBy;
  String? deleteReason;
  
  // Timestamps
  int createdAt;
  int updatedAt;
}

/// LineItem represents a single product in an invoice
class LineItem {
  String id;                    // Unique line item ID
  String invoiceId;             // Reference to parent invoice
  String gemstoneId;            // Product reference
  String gemstoneName;
  
  // Item details
  int quantity;
  double unitPrice;             // Price per unit
  double totalPrice;            // quantity × unitPrice
  double costPerUnit;           // Cost per unit
  double totalCost;             // quantity × costPerUnit
  double commissionFee;         // Commission for this item
  double weightCarat;           // Weight (if applicable)
  
  // Transaction history
  double profitGenerated;       // For this item
  
  // Timestamps
  int createdAt;
  int updatedAt;
}
```

#### Option B: Extend Sale Model (Quick Fix)

**Advantages:**
- Minimal schema changes
- Faster implementation
- Backward compatible with existing data

**Disadvantages:**
- Awkward data structure
- Difficult to query
- Doesn't scale well
- Violates single-responsibility principle

```dart
class Sale {
  // ... existing fields ...
  
  // New fields for multi-item support
  List<SaleLineItem> lineItems;  // Multiple items
  bool isMultiItem;              // Flag to distinguish old/new format
}

class SaleLineItem {
  String gemstoneId;
  String gemstoneName;
  int quantity;
  double unitPrice;
  double costPerUnit;
  double commissionFee;
}
```

**Recommendation:** Use **Option A** (Invoice + LineItem) for long-term maintainability.

---

## 3. Impact Analysis

### 3.1 Inventory Management Impact

**Current Flow:**
```
Sale created → gemstoneId referenced → 
  soldQuantity incremented (derived) →
  remainingQuantity updated (derived) →
  Cost recovery applied to Gemstone model
```

**Multi-Item Impact:**
- ✅ No schema changes needed to Gemstone
- ✅ Cost recovery logic remains per-item
- ⚠️ Must update `updateGemstoneProductLedger()` to handle multiple items per invoice
- ⚠️ Profit calculation must aggregate across line items

**Required Changes:**
1. Update `applyCostRecovery()` to process multiple items
2. Update `updateGemstoneProductLedger()` to sum across line items
3. Update inventory queries to handle line-item-based lookups

### 3.2 Customer Ledger Impact

**Current Flow:**
```
Sale created → customerId referenced →
  applySaleCustomerLedger() called →
  Single ledger entry created →
  customer.currentBalance updated
```

**Multi-Item Impact:**
- ⚠️ One invoice = one ledger entry (not per line item)
- ✅ Ledger entry amount = total invoice amount
- ✅ Existing ledger structure unchanged
- ✅ Payment method applies to entire invoice

**Required Changes:**
1. Update `applySaleCustomerLedger()` to accept Invoice instead of Sale
2. Create single ledger entry per invoice (not per line item)
3. Ledger entry references invoice ID (not sale ID)

### 3.3 Dashboard & Reporting Impact

**Current Metrics:**
```dart
totalSales()              // Sum of sale.amount
totalSalesCommission()    // Sum of sale.commissionFee
netRevenue()              // totalSales - totalSalesCommission
profit()                  // Calculated from gemstone cost recovery
```

**Multi-Item Impact:**
- ✅ Metrics remain the same (sum across line items)
- ✅ Dashboard queries still work (aggregate at invoice level)
- ⚠️ Must update queries to sum line items instead of sales
- ⚠️ Reports need to handle invoice-level vs line-item-level data

**Required Changes:**
1. Update `totalSales()` to sum `Invoice.totalAmount`
2. Update `totalSalesCommission()` to sum `Invoice.totalCommission`
3. Update profit calculations to aggregate from line items
4. Create new report views for invoice-level analysis

### 3.4 Payment & Credit Management Impact

**Current Flow:**
```
Sale created with paymentMethod='credit' →
  customer.currentBalance += sale.amount →
  Ledger entry created with debitAmount
```

**Multi-Item Impact:**
- ✅ Payment method applies to entire invoice
- ✅ Credit balance updated once per invoice
- ✅ Ledger entry structure unchanged
- ✅ No breaking changes to credit logic

**Required Changes:**
1. Update credit validation to check invoice total (not sale total)
2. Update credit limit enforcement at invoice level
3. Ensure payment method is consistent across all line items

---

## 4. Backward Compatibility Analysis

### 4.1 Data Migration Strategy

**Challenge:** Existing Sale records must continue to work alongside new Invoice records.

**Approach 1: Parallel Systems (Recommended)**
```
Existing Sales (old format) → Remain in sales box
New Invoices (new format) → New invoices box
Query layer → Unified view across both

Advantages:
- No data loss
- Gradual migration possible
- Can run both systems in parallel
- Easy rollback if needed

Disadvantages:
- Requires query layer abstraction
- Duplicate data during transition
- More complex business logic
```

**Approach 2: Automatic Migration**
```
On app startup:
  For each existing Sale:
    Create Invoice with single LineItem
    Update all references

Advantages:
- Clean single system
- Simpler queries

Disadvantages:
- One-time migration risk
- Data loss if something fails
- Cannot rollback
```

**Recommendation:** Use **Approach 1** (Parallel Systems) with gradual migration.

### 4.2 UI/UX Backward Compatibility

**Current Sales Page:**
- Single gemstone dropdown
- Single quantity field
- Single cost field

**Multi-Item Sales Page:**
- Add button to add line items
- Line item list with edit/delete
- Invoice-level totals
- Maintain single-item quick entry option

**Backward Compatibility:**
- ✅ Existing single-item sales flow unchanged
- ✅ New multi-item flow is additive
- ✅ Reports show both old and new sales
- ✅ Customer ledger works for both

---

## 5. Risk Assessment

### 5.1 High-Risk Areas

| Risk | Severity | Impact | Mitigation |
|------|----------|--------|-----------|
| **Data Integrity** | 🔴 High | Corrupted line items, lost sales data | Comprehensive validation, transaction-like operations |
| **Profit Calculation** | 🔴 High | Incorrect financial reporting | Unit tests for cost recovery, profit aggregation |
| **Customer Ledger** | 🔴 High | Incorrect customer balances | Ledger reconciliation tools, audit logs |
| **Inventory Deduction** | 🟡 Medium | Stock quantity mismatches | Detailed logging, inventory reconciliation |
| **Performance** | 🟡 Medium | Slow queries with large datasets | Indexing strategy, query optimization |

### 5.2 Medium-Risk Areas

| Risk | Severity | Impact | Mitigation |
|------|----------|--------|-----------|
| **Soft Delete Logic** | 🟡 Medium | Incomplete deletion, orphaned records | Cascade delete strategy, referential integrity |
| **Broker Sales Integration** | 🟡 Medium | Incompatible with broker flow | Separate broker invoice model if needed |
| **Photo Attachments** | 🟡 Medium | Unclear which item photo belongs to | Item-level photo support, UI clarification |
| **Payment Reconciliation** | 🟡 Medium | Partial payment tracking | Invoice-level payment status field |

### 5.3 Low-Risk Areas

| Risk | Severity | Impact | Mitigation |
|------|----------|--------|-----------|
| **Dashboard Display** | 🟢 Low | Metrics aggregation | Update queries, add tests |
| **Report Generation** | 🟢 Low | Report accuracy | New report templates, validation |
| **Customer UI** | 🟢 Low | User confusion | Clear UX, onboarding guide |

---

## 6. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

**Objective:** Create new data models and migration infrastructure

**Tasks:**
1. Create Invoice and LineItem models with Hive adapters
2. Create parallel invoices and lineItems boxes
3. Implement Invoice TypeAdapter and LineItem TypeAdapter
4. Create migration utility to convert existing Sales to Invoices
5. Add comprehensive unit tests for new models
6. Update LocalDb with new box accessors

**Deliverables:**
- New data models
- Migration utilities
- Unit test suite
- No UI changes yet

**Risk Level:** 🟢 Low (data layer only)

### Phase 2: Business Logic (Weeks 3-4)

**Objective:** Implement core business logic for multi-item sales

**Tasks:**
1. Update `applySaleCustomerLedger()` to handle invoices
2. Update `reverseSaleCustomerLedger()` for invoices
3. Implement invoice-level cost recovery
4. Update profit calculation to aggregate line items
5. Create invoice validation logic
6. Update inventory tracking for line items
7. Add comprehensive business logic tests

**Deliverables:**
- Updated business logic
- Invoice validation rules
- Test coverage for all scenarios
- No UI changes yet

**Risk Level:** 🟡 Medium (business logic complexity)

### Phase 3: Query Layer (Week 5)

**Objective:** Create unified query interface

**Tasks:**
1. Create abstract SaleRecord interface
2. Implement adapters for Sale and Invoice
3. Create unified query methods (totalSales, profit, etc.)
4. Update dashboard queries
5. Update report queries
6. Add query layer tests

**Deliverables:**
- Unified query interface
- Updated dashboard queries
- Updated report queries
- Query layer tests

**Risk Level:** 🟡 Medium (query complexity)

### Phase 4: UI Implementation (Weeks 6-7)

**Objective:** Build multi-item sales UI

**Tasks:**
1. Create LineItemForm widget
2. Update SalesPage to support multi-item entry
3. Implement add/edit/delete line items
4. Add invoice-level summary
5. Implement invoice validation UI
6. Add line item list display
7. Create UI tests

**Deliverables:**
- Multi-item sales form
- Line item management UI
- Invoice summary display
- UI tests

**Risk Level:** 🟡 Medium (UI complexity)

### Phase 5: Integration & Testing (Week 8)

**Objective:** Integrate all components and comprehensive testing

**Tasks:**
1. End-to-end integration testing
2. Backward compatibility testing
3. Data migration testing
4. Performance testing
5. User acceptance testing
6. Documentation updates
7. PAT workflow validation

**Deliverables:**
- Integrated system
- Test reports
- Migration validation
- Documentation

**Risk Level:** 🟡 Medium (integration complexity)

### Phase 6: Gradual Rollout (Weeks 9-10)

**Objective:** Deploy and monitor

**Tasks:**
1. Deploy to staging
2. Monitor for issues
3. Gradual user rollout
4. Collect feedback
5. Bug fixes and refinements
6. Deploy to production

**Deliverables:**
- Production deployment
- Monitoring setup
- User documentation

**Risk Level:** 🟢 Low (controlled rollout)

---

## 7. Recommended Design Decisions

### 7.1 Invoice Number Generation

**Decision:** Use sequential invoice numbers

```dart
// Format: INV-YYYY-MM-DD-XXXX
// Example: INV-2026-07-04-0001

static String generateInvoiceNumber() {
  final now = DateTime.now();
  final dateStr = DateFormat('yyyy-MM-dd').format(now);
  final count = invoices()
      .values
      .where((inv) => inv.invoiceNumber.startsWith('INV-$dateStr'))
      .length + 1;
  return 'INV-$dateStr-${count.toString().padLeft(4, '0')}';
}
```

**Advantages:**
- Human-readable
- Sortable by date
- Easy to track
- No collisions

### 7.2 Line Item Ordering

**Decision:** Maintain insertion order with explicit sequence numbers

```dart
class LineItem {
  int sequenceNumber;  // 1, 2, 3, ... for display order
  // ... other fields
}
```

**Advantages:**
- Clear display order
- Easy to reorder
- Supports undo/redo

### 7.3 Partial Payments

**Decision:** Support invoice-level payment status

```dart
class Invoice {
  String paymentStatus;  // pending | partial | paid
  double amountPaid;     // Track partial payments
  List<Payment> payments; // Payment history
}

class Payment {
  String id;
  String invoiceId;
  double amount;
  String method;
  int paymentDate;
}
```

**Advantages:**
- Flexible payment handling
- Audit trail
- Supports credit scenarios

### 7.4 Line Item Deletion

**Decision:** Support soft delete for line items

```dart
class LineItem {
  bool isDeleted;
  int? deletedAt;
  
  // Recalculate invoice totals excluding deleted items
}
```

**Advantages:**
- Maintains audit trail
- Supports undo
- Data integrity

---

## 8. Database Schema Considerations

### 8.1 Hive Box Structure

**Current:**
```
Box<Sale> 'sales'
  - Single item per record
  - Direct gemstone reference
```

**Proposed:**
```
Box<Invoice> 'invoices'
  - Invoice header data
  - References to line items

Box<LineItem> 'lineItems'
  - Individual line items
  - References back to invoice
  - References to gemstone
```

### 8.2 Query Performance

**Concern:** Querying across multiple boxes

**Solution:** Create materialized views in LocalDb

```dart
class InvoiceWithItems {
  Invoice invoice;
  List<LineItem> lineItems;
  
  double get totalAmount => lineItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalCost => lineItems.fold(0, (sum, item) => sum + item.totalCost);
}

static InvoiceWithItems getInvoiceWithItems(String invoiceId) {
  final invoice = invoices().get(invoiceId);
  final lineItems = lineItemsBox.values
      .where((item) => item.invoiceId == invoiceId)
      .toList();
  return InvoiceWithItems(invoice, lineItems);
}
```

---

## 9. Testing Strategy

### 9.1 Unit Tests

**Data Model Tests:**
- Invoice creation and validation
- LineItem creation and validation
- Calculation accuracy (totals, costs, profits)
- Soft delete logic

**Business Logic Tests:**
- Cost recovery with multiple items
- Customer ledger entries
- Inventory deduction
- Profit calculation
- Credit balance updates

**Query Tests:**
- Invoice retrieval
- Line item aggregation
- Dashboard metrics
- Report generation

### 9.2 Integration Tests

- End-to-end invoice creation
- Multi-item sales workflow
- Customer ledger reconciliation
- Inventory accuracy
- Profit reporting

### 9.3 Backward Compatibility Tests

- Existing Sales still queryable
- Existing reports still work
- Migration accuracy
- Data integrity after migration

### 9.4 Performance Tests

- Query performance with 10k+ invoices
- Line item aggregation performance
- Dashboard load time
- Report generation time

---

## 10. Rollback Strategy

### 10.1 Rollback Points

**Phase 1 Rollback:**
- Delete new boxes
- No data loss
- Easy rollback

**Phase 2-3 Rollback:**
- Keep new boxes but disable UI
- Revert business logic changes
- Maintain parallel systems

**Phase 4-5 Rollback:**
- Keep all changes but disable multi-item UI
- Fall back to single-item only
- Requires data cleanup

### 10.2 Rollback Procedures

```
1. Identify rollback point
2. Backup current database
3. Revert code to previous version
4. Clear new boxes if needed
5. Verify data integrity
6. Test single-item flow
7. Monitor for issues
```

---

## 11. Success Criteria

### 11.1 Functional Requirements

- ✅ Create invoices with 1-N line items
- ✅ Edit/delete line items
- ✅ Calculate invoice totals correctly
- ✅ Update inventory for each line item
- ✅ Update customer ledger for invoice
- ✅ Calculate profit across line items
- ✅ Support all payment methods
- ✅ Maintain soft delete capability

### 11.2 Non-Functional Requirements

- ✅ No performance degradation
- ✅ 100% backward compatible
- ✅ 95%+ test coverage
- ✅ Zero data loss during migration
- ✅ Dashboard load time < 2s
- ✅ Report generation < 5s

### 11.3 User Experience

- ✅ Intuitive multi-item entry
- ✅ Clear invoice summary
- ✅ Easy line item management
- ✅ Fast invoice creation
- ✅ Clear error messages

---

## 12. Recommended Next Steps

### Immediate (This Week)

1. **Review & Approval**
   - Share this review with stakeholders
   - Get approval for Phase 1 approach
   - Identify any additional requirements

2. **Detailed Design**
   - Create detailed ERD (Entity Relationship Diagram)
   - Define exact field types and constraints
   - Create migration scripts

3. **Planning**
   - Create detailed task breakdown
   - Assign team members
   - Set up development environment

### Short Term (Next 2 Weeks)

1. **Phase 1 Implementation**
   - Create new data models
   - Implement Hive adapters
   - Create migration utilities
   - Write comprehensive unit tests

2. **Code Review**
   - Review new models
   - Validate Hive adapter implementation
   - Approve test coverage

3. **Documentation**
   - Document new models
   - Create migration guide
   - Update developer docs

### Medium Term (Weeks 3-4)

1. **Phase 2-3 Implementation**
   - Implement business logic
   - Create query layer
   - Comprehensive testing

2. **Integration Testing**
   - Test across all modules
   - Verify backward compatibility
   - Performance testing

---

## 13. Conclusion

Multi-item sales is a **significant but achievable enhancement** to the Gemstone Management system. The recommended approach uses a **parallel Invoice + LineItem model** with **gradual migration** to maintain backward compatibility and minimize risk.

**Key Success Factors:**
1. Comprehensive data validation at every step
2. Extensive unit and integration testing
3. Gradual rollout with monitoring
4. Clear rollback procedures
5. Strong backward compatibility

**Timeline:** 8-10 weeks for full implementation and deployment

**Risk Level:** 🟡 Medium (manageable with proper planning)

**Recommendation:** Proceed with Phase 1 implementation after stakeholder approval.

---

## Appendix A: Glossary

| Term | Definition |
|------|-----------|
| **Invoice** | A single customer transaction with multiple line items |
| **LineItem** | A single product entry within an invoice |
| **Cost Recovery** | Process of recovering purchase cost from sale revenue |
| **Customer Ledger** | Transaction history for a customer account |
| **Soft Delete** | Marking record as deleted without removing from database |
| **Materialized View** | Pre-computed query result stored for performance |
| **Backward Compatibility** | Ability to work with existing data and code |

---

## Appendix B: Related Files

- `lib/core/local/models.dart` - Data models
- `lib/core/local/local_db.dart` - Database access layer
- `lib/features/sales/presentation/pages/sales_page.dart` - Sales UI
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - Dashboard
- `lib/features/reports/presentation/pages/reports_page.dart` - Reports

---

**Document Version:** 1.0  
**Last Updated:** July 4, 2026  
**Status:** Ready for Review
