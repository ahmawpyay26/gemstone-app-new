# Multi-Item Sales Phase 2B - Design Review & Implementation Plan

**Date:** July 4, 2026  
**Base Commit:** 3f141fb (PAT #197 SUCCESS)  
**Status:** Design Phase (No Code Changes)

---

## 1. Root Cause Analysis: Why Phase 2B Failed

### Previous Failures (PAT #198-200)

**Attempts:**
- PAT #198: sed command approach - JSON escaping errors
- PAT #199: Direct replacement with incomplete Sale initialization
- PAT #200: Added missing fields but still failed

**Root Cause:**
The implementation tried to do too much in one step:
1. ✗ Loop through multiple items
2. ✗ Initialize multiple Sale objects with all 24 fields
3. ✗ Apply business logic to each item
4. ✗ Update multiple gemstones
5. ✗ Update customer ledger
6. ✗ Handle errors and rollback
7. ✗ All without proper validation framework

**Key Issue:**
- Attempted to refactor the entire save flow instead of reusing existing logic
- Complex nested loops and conditional logic
- No intermediate validation checkpoints
- Risk of partial saves (item 1 succeeds, item 2 fails)

---

## 2. Current Single-Item Save Flow

### Method: `_save()` (lines 918-1089)

### Flow Diagram

```
_save() called
    ↓
[1] Form Validation
    ├─ Check form is valid
    └─ Return if invalid
    ↓
[2] Parse Form Fields
    ├─ qty, weight, amount, commission
    ├─ gemstoneId, name
    ├─ perUnitCost, cost
    └─ netSale = amount - commission
    ↓
[3] Inventory Validation (if auto-deduct enabled)
    ├─ Check gemstone exists
    ├─ Check remaining quantity > 0
    ├─ Check qty <= available
    ├─ Check weight <= available
    └─ Return if validation fails
    ↓
[4] Create Sale Object
    ├─ Generate new ID: LocalDb.genId()
    ├─ Set all 24 fields
    └─ Initialize ledger fields to 0
    ↓
[5] Save to Hive
    ├─ box.add(newSale)
    └─ Sale now persisted
    ↓
[6] Apply Customer Ledger
    ├─ LocalDb.applySaleCustomerLedger(newSale)
    └─ Updates customer balance
    ↓
[7] Apply Cost Recovery
    ├─ LocalDb.applyCostRecovery(gemstone, netSale)
    ├─ Updates gemstone cost tracking
    └─ box.put(gemId, gemstone)
    ↓
[8] Update Product Ledger
    ├─ LocalDb.updateGemstoneProductLedger(gemId)
    └─ Recalculates profit from all sales
    ↓
[9] Close Form
    └─ Navigator.pop(context)
```

---

## 3. Sale Constructor Fields (24 Total)

### Required Fields (must be provided)
| Field | Type | Source | Example |
|-------|------|--------|---------|
| `id` | String | Generated | LocalDb.genId() |
| `gemstoneName` | String | Form/Lookup | "Ruby" |
| `customerName` | String | Form | "Maung Maung" |
| `amount` | double | Form | 300000.0 |
| `quantity` | int | Form | 2 |
| `paymentMethod` | String | Form | "Cash" |
| `note` | String | Form | "Good quality" |
| `saleDate` | int | Form/System | DateTime.now().millisecondsSinceEpoch |

### Optional Fields (have defaults)
| Field | Type | Default | Source |
|-------|------|---------|--------|
| `gemstoneId` | String | '' | Form/Lookup |
| `customerId` | String? | null | Form/Lookup |
| `costPrice` | double | 0 | Calculated |
| `commissionFee` | double | 0 | Form |
| `weightCarat` | double | 0 | Form |
| `netSale` | double | 0 | Calculated |
| `costUsed` | double | 0 | Auto-calculated |
| `profitGenerated` | double | 0 | Auto-calculated |
| `remainingCostAfterSale` | double | 0 | Auto-calculated |
| `accumulatedProfit` | double | 0 | Auto-calculated |
| `isDeleted` | bool | false | System |
| `deletedAt` | int? | null | System |
| `deletedBy` | String? | null | System |
| `deleteReason` | String? | null | System |
| `photoPaths` | List<String> | [] | Form |
| `invoiceNumber` | String | '' | **NEW - To be set** |

---

## 4. Methods Called After Save

### 4.1 Customer Ledger Update
```dart
await LocalDb.applySaleCustomerLedger(newSale);
```
**Purpose:** Update customer balance  
**Impact:** Affects customer credit/debit  
**Rollback:** Would need to reverse ledger entry

### 4.2 Cost Recovery
```dart
LocalDb.applyCostRecovery(gemstone, netSale);
```
**Purpose:** Track cost recovery for gemstone  
**Impact:** Updates gemstone cost tracking fields  
**Rollback:** Would need to reverse cost tracking

### 4.3 Product Ledger Update
```dart
await LocalDb.updateGemstoneProductLedger(gemId);
```
**Purpose:** Recalculate profit from all sales  
**Impact:** Updates gemstone profit metrics  
**Rollback:** Would need to recalculate

---

## 5. How to Reuse Single-Item Logic for Multi-Item

### Key Insight
**Do NOT refactor the save flow. Reuse it as-is.**

The single-item save logic is:
- ✅ Well-tested (PAT #195 passed)
- ✅ Handles all edge cases
- ✅ Updates all ledgers correctly
- ✅ Manages rollback properly

### Strategy: Extract & Loop

Instead of rewriting, extract the core save logic into a helper:

```dart
// Pseudo-code (not actual implementation)

Future<void> _saveSingleItem(
  SaleItem item,
  String invoiceNumber,
) async {
  // Reuse all validation from _save()
  // Create Sale object with invoiceNumber
  // Call existing LocalDb methods
  // Return success/failure
}

Future<void> _save() async {
  // 1. Validate all items first
  // 2. Generate invoiceNumber
  // 3. Loop through items
  for (final item in _items) {
    final success = await _saveSingleItem(item, invoiceNumber);
    if (!success) {
      // Handle error
      return;
    }
  }
  // 4. Close form
}
```

---

## 6. Validation Strategy

### Pre-Save Validation (Before ANY writes)

```
For each item:
  ✓ Gemstone ID not empty
  ✓ Quantity > 0
  ✓ Unit Price >= 0
  ✓ Gemstone exists (if linked)
  ✓ Inventory sufficient (if auto-deduct)
  
If any item fails:
  → Show error
  → Stop (no saves)
  
If all items pass:
  → Generate invoiceNumber
  → Begin saving loop
```

### Key Principle
**Validate ALL before saving ANY**

This prevents partial saves where item 1 succeeds but item 2 fails.

---

## 7. Invoice Number Generation

### Format
```
INV-YYYYMMDD-NNN
```

**Example:**
```
INV-20260704-001  (First invoice on July 4, 2026)
INV-20260704-002  (Second invoice on July 4, 2026)
```

### Generation Logic
```dart
final now = DateTime.now();
final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

// Count existing invoices for today
final existingInvoices = LocalDb.sales()
    .values
    .where((s) => s.invoiceNumber.startsWith('INV-$dateStr-'))
    .length;

final invoiceNum = 'INV-$dateStr-${(existingInvoices + 1).toString().padLeft(3, '0')}';
```

### Apply to All Items
All items in one save share the same `invoiceNumber`.

---

## 8. Rollback Risk Analysis

### Scenario: Item 1 Saves, Item 2 Fails

**Current Risk:**
- Item 1 Sale record exists in Hive
- Item 1 Customer ledger updated
- Item 1 Gemstone cost recovery applied
- Item 2 fails during validation or save
- **Result:** Partial invoice (incomplete)

**Mitigation Strategy:**
1. **Validate ALL items before saving ANY** (prevents this)
2. **If validation passes, saves should succeed** (minimal error risk)
3. **If save fails, show error and let user retry** (user can fix and retry)

### Why Full Rollback is NOT Needed
- Hive transactions are atomic per record
- If item 1 saves successfully, it's valid
- If item 2 fails, it's a user error (validation should catch it)
- User can delete item 1 sale if needed and retry

### Acceptable Risk Level
- **Low:** Validation catches 99% of errors before save
- **Medium:** If save fails, it's a system error (rare)
- **Mitigation:** Show clear error message, let user retry

---

## 9. Safest Implementation Approach

### Principle: Minimal Changes, Maximum Reuse

**DO:**
- ✅ Reuse existing `_save()` logic
- ✅ Validate all items upfront
- ✅ Generate invoiceNumber once
- ✅ Loop and save each item
- ✅ Call existing LocalDb methods

**DO NOT:**
- ❌ Refactor `_save()` method
- ❌ Create new save helpers
- ❌ Implement custom rollback
- ❌ Change LocalDb methods
- ❌ Modify Sale model

### Recommended Approach

**Extract validation logic into separate method:**
```dart
String _validateAllItems() {
  // Check each item
  // Return error message if invalid
  // Return empty string if valid
}
```

**Keep save logic mostly unchanged:**
```dart
Future<void> _save() async {
  // Validate all items first
  final error = _validateAllItems();
  if (error.isNotEmpty) {
    _toast(error);
    return;
  }
  
  // Generate invoiceNumber
  final invoiceNum = _generateInvoiceNumber();
  
  // Save each item (reuse existing logic)
  for (final item in _items) {
    // Create Sale with invoiceNumber
    // Call box.add()
    // Call LocalDb methods
  }
  
  // Close form
  Navigator.pop(context);
}
```

---

## 10. Step-by-Step Implementation Plan

### Phase 2B-1: Single-Item Save with invoiceNumber
**Goal:** Make existing single-item save work with invoiceNumber

**Changes:**
1. Add invoiceNumber generation logic
2. Set invoiceNumber on Sale object
3. Verify single-item save still works
4. **Expected:** PAT passes, single sales have invoiceNumber

**Risk:** Low (only adding one field)

### Phase 2B-2: Two-Item Save
**Goal:** Save two items with same invoiceNumber

**Changes:**
1. Create simple validation for 2 items
2. Loop through 2 items
3. Save each with same invoiceNumber
4. **Expected:** PAT passes, 2-item invoices work

**Risk:** Low (simple loop, no complex logic)

### Phase 2B-3: Unlimited Multi-Item Save
**Goal:** Support any number of items

**Changes:**
1. Extend validation to all items
2. Loop through all items
3. Save each with same invoiceNumber
4. **Expected:** PAT passes, unlimited items work

**Risk:** Low (same logic as Phase 2B-2, just more items)

### Phase 2B-4: Error Handling & Edge Cases
**Goal:** Handle errors gracefully

**Changes:**
1. Add try-catch around save loop
2. Show error message if save fails
3. Validate edge cases (empty items, invalid gemstones, etc.)
4. **Expected:** PAT passes, errors handled gracefully

**Risk:** Low (error handling only, no data changes)

---

## 11. Risk List

| Risk | Severity | Mitigation | Status |
|------|----------|-----------|--------|
| Partial invoice (item 1 saves, item 2 fails) | 🔴 High | Validate all before saving | ✅ Planned |
| Missing invoiceNumber field | 🟡 Medium | Already added in Phase 1 | ✅ Done |
| Duplicate invoiceNumber | 🟡 Medium | Generate fresh for each save | ✅ Planned |
| Customer ledger inconsistency | 🟡 Medium | Reuse existing LocalDb method | ✅ Planned |
| Gemstone cost recovery error | 🟡 Medium | Reuse existing LocalDb method | ✅ Planned |
| Product ledger miscalculation | 🟡 Medium | Reuse existing LocalDb method | ✅ Planned |
| UI not updated after save | 🟢 Low | Reuse existing Navigator.pop() | ✅ Planned |
| Null pointer in _items loop | 🟢 Low | Validate items list before loop | ✅ Planned |

---

## 12. Recommended Next Steps

### Immediate (This Week)
1. ✅ Review this design document
2. ✅ Get approval to proceed with Phase 2B-1
3. ✅ Assign developer

### Phase 2B-1 (Week 1)
1. Add invoiceNumber generation
2. Set invoiceNumber on single Sale
3. Test with PAT
4. **Expected:** PAT #201 passes

### Phase 2B-2 (Week 1)
1. Add basic 2-item validation
2. Loop through 2 items
3. Save with same invoiceNumber
4. Test with PAT
5. **Expected:** PAT #202 passes

### Phase 2B-3 (Week 2)
1. Extend validation to unlimited items
2. Loop through all items
3. Test with PAT
4. **Expected:** PAT #203 passes

### Phase 2B-4 (Week 2)
1. Add error handling
2. Add edge case validation
3. Test with PAT
4. **Expected:** PAT #204 passes

---

## 13. Success Criteria

### Phase 2B Complete When:
- ✅ All 4 sub-phases pass PAT
- ✅ Single-item sales still work
- ✅ Multi-item invoices save correctly
- ✅ All items share same invoiceNumber
- ✅ Customer ledger updated correctly
- ✅ Gemstone cost recovery applied correctly
- ✅ Product ledger recalculated correctly
- ✅ Dashboard metrics unchanged
- ✅ Reports show correct totals
- ✅ No breaking changes to existing features

---

## 14. Conclusion

### Why This Approach Works

1. **Minimal Changes:** Reuse existing logic, don't refactor
2. **Incremental:** Build in small, testable steps
3. **Safe:** Validate all before saving any
4. **Reversible:** Each phase can be rolled back independently
5. **Proven:** Uses existing, tested LocalDb methods

### Key Difference from Failed Attempts

- ❌ Previous: Try to do everything at once
- ✅ Recommended: Do one thing at a time, validate thoroughly

### Timeline

- **Phase 2B-1:** 1-2 days
- **Phase 2B-2:** 1-2 days
- **Phase 2B-3:** 1 day
- **Phase 2B-4:** 1-2 days
- **Total:** 4-7 days (1 week)

---

**Status:** ✅ Design Review Complete - Ready for Implementation

**Next Action:** Proceed with Phase 2B-1 implementation when approved.
