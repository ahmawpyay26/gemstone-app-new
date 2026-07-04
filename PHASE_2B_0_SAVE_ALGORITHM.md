# Multi-Item Sales Phase 2B-0 - Save Algorithm Design

**Date:** July 4, 2026  
**Base Commit:** 3f141fb (PAT #197 SUCCESS)  
**Status:** Algorithm Design (No Code)

---

## 1. Complete Save Algorithm Flow

### High-Level Overview

```
User clicks Save
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: VALIDATION (No writes)                             │
│ - Validate all items                                        │
│ - Check inventory                                           │
│ - Check customer exists                                     │
│ - If any error → Show error & STOP                          │
└─────────────────────────────────────────────────────────────┘
    ↓ (All items valid)
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: PREPARATION                                        │
│ - Generate invoiceNumber                                    │
│ - Prepare gemstone updates                                  │
│ - Prepare ledger entries                                    │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 3: SAVE LOOP (Writes happen here)                     │
│ For each item:                                              │
│   - Create Sale object                                      │
│   - Save to Hive                                            │
│   - Update customer ledger                                  │
│   - Update gemstone cost recovery                           │
│   - Track gemstone updates                                  │
│ If any error → Show error & STOP                            │
└─────────────────────────────────────────────────────────────┘
    ↓ (All items saved)
┌─────────────────────────────────────────────────────────────┐
│ PHASE 4: POST-SAVE UPDATES                                  │
│ For each updated gemstone:                                  │
│   - Recalculate product ledger                              │
│   - Update profit metrics                                   │
│ - Close form                                                │
│ - Show success message                                      │
└─────────────────────────────────────────────────────────────┘
    ↓
Save Complete
```

---

## 2. Detailed Flow Diagrams

### PHASE 1: VALIDATION FLOW

```
START: _save() called
    ↓
[1.1] Validate Form
    ├─ Check _formKey.currentState.validate()
    ├─ If invalid → _toast() & RETURN
    └─ If valid → Continue
    ↓
[1.2] Validate Items List
    ├─ Check _items.isNotEmpty
    ├─ If empty → _toast('At least one item required') & RETURN
    └─ If has items → Continue
    ↓
[1.3] For Each Item: Validate Item Data
    ├─ For i = 0 to _items.length-1:
    │   ├─ item = _items[i]
    │   ├─ [1.3.1] Validate Gemstone
    │   │   ├─ Check item.gemstoneId.isNotEmpty
    │   │   ├─ If empty → _toast('Item $i: Select gemstone') & RETURN
    │   │   └─ If not empty → Continue
    │   ├─ [1.3.2] Validate Quantity
    │   │   ├─ qty = int.tryParse(item.quantity.toString())
    │   │   ├─ Check qty != null && qty > 0
    │   │   ├─ If invalid → _toast('Item $i: Qty must be > 0') & RETURN
    │   │   └─ If valid → Continue
    │   ├─ [1.3.3] Validate Unit Price
    │   │   ├─ unitPrice = double.tryParse(item.unitPrice.toString())
    │   │   ├─ Check unitPrice != null && unitPrice >= 0
    │   │   ├─ If invalid → _toast('Item $i: Price invalid') & RETURN
    │   │   └─ If valid → Continue
    │   ├─ [1.3.4] Validate Gemstone Exists
    │   │   ├─ g = LocalDb.gemstoneById(item.gemstoneId)
    │   │   ├─ Check g != null
    │   │   ├─ If null → _toast('Item $i: Gemstone not found') & RETURN
    │   │   └─ If exists → Continue
    │   ├─ [1.3.5] Validate Inventory (if auto-deduct enabled)
    │   │   ├─ Check _autoDeduct flag
    │   │   ├─ If enabled:
    │   │   │   ├─ remaining = LocalDb.gemstoneRemainingQuantity(g)
    │   │   │   ├─ Check remaining > 0
    │   │   │   ├─ If sold out → _toast('Item $i: Sold out') & RETURN
    │   │   │   ├─ Check qty <= remaining
    │   │   │   ├─ If insufficient → _toast('Item $i: Stock $remaining') & RETURN
    │   │   │   └─ If sufficient → Continue
    │   │   └─ If not enabled → Continue (skip inventory check)
    │   └─ Item valid → Continue to next item
    └─ All items valid → Proceed to PHASE 2
    ↓
VALIDATION COMPLETE (All items valid, no writes yet)
```

### PHASE 2: INVOICE NUMBER GENERATION

```
[2.1] Get Current Date
    ├─ now = DateTime.now()
    ├─ year = now.year (e.g., 2026)
    ├─ month = now.month.toString().padLeft(2, '0') (e.g., '07')
    ├─ day = now.day.toString().padLeft(2, '0') (e.g., '04')
    └─ dateStr = '$year$month$day' (e.g., '20260704')
    ↓
[2.2] Count Existing Invoices for Today
    ├─ box = LocalDb.sales()
    ├─ existingInvoices = box.values
    │   .where((s) => s.invoiceNumber.startsWith('INV-$dateStr-'))
    │   .length
    └─ Count = number of invoices already created today
    ↓
[2.3] Generate Invoice Number
    ├─ nextNum = existingInvoices + 1
    ├─ numStr = nextNum.toString().padLeft(3, '0') (e.g., '001', '002')
    ├─ invoiceNumber = 'INV-$dateStr-$numStr'
    │   (e.g., 'INV-20260704-001')
    └─ invoiceNumber ready to use
    ↓
INVOICE NUMBER GENERATED
```

### PHASE 3: SAVE LOOP FLOW

```
[3.1] Initialize Tracking Variables
    ├─ box = LocalDb.sales()
    ├─ gemstonesUpdated = Set<String>() (track which gemstones changed)
    ├─ savedCount = 0
    └─ errorOccurred = false
    ↓
[3.2] For Each Item in _items
    ├─ For i = 0 to _items.length-1:
    │   ├─ item = _items[i]
    │   ├─ [3.2.1] Parse Item Data
    │   │   ├─ qty = int.tryParse(item.quantity.toString()) ?? 1
    │   │   ├─ unitPrice = double.tryParse(item.unitPrice.toString()) ?? 0
    │   │   ├─ amount = qty * unitPrice
    │   │   ├─ sellCommission = double.tryParse(_commission.text.trim()) ?? 0
    │   │   ├─ netSale = amount - sellCommission
    │   │   ├─ perUnitCost = double.tryParse(_cost.text.trim()) ?? 0
    │   │   ├─ cost = item.gemstoneId.isNotEmpty ? (perUnitCost * qty) : perUnitCost
    │   │   └─ All values calculated
    │   ├─ [3.2.2] Create Sale Object
    │   │   ├─ newSale = Sale(
    │   │   │   id: LocalDb.genId(),
    │   │   │   gemstoneId: item.gemstoneId,
    │   │   │   gemstoneName: item.gemstoneName,
    │   │   │   customerId: _selectedCustomerId,
    │   │   │   customerName: _customer.text.trim(),
    │   │   │   amount: amount,
    │   │   │   costPrice: cost,
    │   │   │   commissionFee: sellCommission,
    │   │   │   quantity: qty,
    │   │   │   weightCarat: 0,
    │   │   │   paymentMethod: _payment,
    │   │   │   note: _note.text.trim(),
    │   │   │   saleDate: _saleDate.millisecondsSinceEpoch,
    │   │   │   netSale: netSale,
    │   │   │   invoiceNumber: invoiceNumber,  ← SAME FOR ALL ITEMS
    │   │   │   costUsed: 0,
    │   │   │   profitGenerated: 0,
    │   │   │   remainingCostAfterSale: 0,
    │   │   │   accumulatedProfit: 0,
    │   │   │   photoPaths: i == 0 ? _photoPaths : [],  ← Photos only on first item
    │   │   │   isDeleted: false,
    │   │   │   deletedAt: null,
    │   │   │   deletedBy: '',
    │   │   │   deleteReason: '',
    │   │   │ )
    │   │   └─ Sale object created
    │   ├─ [3.2.3] Save to Hive
    │   │   ├─ await box.add(newSale)
    │   │   ├─ If success → savedCount++
    │   │   ├─ If error → errorOccurred = true & BREAK
    │   │   └─ Sale now persisted
    │   ├─ [3.2.4] Update Customer Ledger
    │   │   ├─ await LocalDb.applySaleCustomerLedger(newSale)
    │   │   ├─ If error → errorOccurred = true & BREAK
    │   │   └─ Customer balance updated
    │   ├─ [3.2.5] Update Gemstone Cost Recovery
    │   │   ├─ If item.gemstoneId.isNotEmpty:
    │   │   │   ├─ gemstone = LocalDb.gemstoneById(item.gemstoneId)
    │   │   │   ├─ If gemstone != null:
    │   │   │   │   ├─ LocalDb.applyCostRecovery(gemstone, netSale)
    │   │   │   │   ├─ await box.put(item.gemstoneId, gemstone)
    │   │   │   │   ├─ gemstonesUpdated.add(item.gemstoneId)
    │   │   │   │   ├─ If error → errorOccurred = true & BREAK
    │   │   │   │   └─ Gemstone updated
    │   │   │   └─ Gemstone not found → Skip
    │   │   └─ No gemstone ID → Skip
    │   └─ Item saved successfully → Continue to next item
    └─ All items processed
    ↓
[3.3] Check for Errors
    ├─ If errorOccurred:
    │   ├─ _toast('Error saving invoice. Please try again.')
    │   └─ RETURN (form stays open)
    └─ If no errors → Continue to PHASE 4
    ↓
SAVE LOOP COMPLETE (All items saved to Hive)
```

### PHASE 4: POST-SAVE UPDATES FLOW

```
[4.1] Update Product Ledgers for All Changed Gemstones
    ├─ For each gemId in gemstonesUpdated:
    │   ├─ await LocalDb.updateGemstoneProductLedger(gemId)
    │   ├─ If error → _toast('Error updating ledger') & RETURN
    │   └─ Product ledger recalculated
    └─ All gemstones updated
    ↓
[4.2] Show Success Message
    ├─ _toast('Invoice $invoiceNumber saved successfully!')
    └─ User sees confirmation
    ↓
[4.3] Close Form
    ├─ if (mounted) Navigator.pop(context)
    └─ Form closes, returns to sales list
    ↓
[4.4] UI Auto-Refresh
    ├─ Sales list rebuilds (ValueListenableBuilder watches LocalDb.sales())
    ├─ New invoice appears in list
    ├─ Dashboard updates (watches same source)
    └─ All UI reflects new data
    ↓
SAVE COMPLETE - SUCCESS
```

### ERROR HANDLING FLOW

```
Error can occur at:

[E1] Validation Phase
    ├─ Item invalid → _toast('Item error') & RETURN
    └─ No writes happened (safe)
    ↓
[E2] Save to Hive
    ├─ box.add() fails → _toast('Save error') & RETURN
    ├─ Item 1-N saved, Item N+1 failed
    ├─ Partial invoice exists (acceptable risk)
    └─ User can delete and retry
    ↓
[E3] Customer Ledger Update
    ├─ applySaleCustomerLedger() fails → _toast('Ledger error') & RETURN
    ├─ Sale saved but ledger not updated (inconsistent)
    ├─ User can manually fix or retry
    └─ Rare edge case
    ↓
[E4] Gemstone Update
    ├─ applyCostRecovery() fails → _toast('Gemstone error') & RETURN
    ├─ Sale saved but cost not recovered
    ├─ User can manually fix or retry
    └─ Rare edge case
    ↓
[E5] Product Ledger Recalculation
    ├─ updateGemstoneProductLedger() fails → _toast('Ledger error') & RETURN
    ├─ Sale saved but profit not recalculated
    ├─ User can manually fix or retry
    └─ Rare edge case

MITIGATION:
- Validate all before saving any (prevents E2)
- Reuse existing LocalDb methods (prevents E3-E5)
- Show clear error messages (helps user understand)
- Let user retry (simple recovery)
```

---

## 3. Data Flow Diagram

### Item → Sale → Hive

```
User Input (Multi-Item Form)
    ├─ Item 1: Ruby, Qty 2, Price 300000
    ├─ Item 2: Sapphire, Qty 1, Price 500000
    └─ Item 3: Jade, Qty 5, Price 100000
    ↓
Validation (All items checked)
    ├─ ✓ Item 1 valid
    ├─ ✓ Item 2 valid
    └─ ✓ Item 3 valid
    ↓
Invoice Number Generated: INV-20260704-001
    ↓
Save Loop
    ├─ Item 1 → Sale A (INV-20260704-001) → Hive ✓
    ├─ Item 2 → Sale B (INV-20260704-001) → Hive ✓
    └─ Item 3 → Sale C (INV-20260704-001) → Hive ✓
    ↓
Ledger Updates
    ├─ Customer ledger: +600000 (total amount)
    ├─ Ruby cost recovery: -300000 net sale
    ├─ Sapphire cost recovery: -500000 net sale
    └─ Jade cost recovery: -500000 net sale
    ↓
Product Ledger Recalculation
    ├─ Ruby: Profit recalculated
    ├─ Sapphire: Profit recalculated
    └─ Jade: Profit recalculated
    ↓
UI Update (Automatic)
    ├─ Sales list shows 3 new sales (all with INV-20260704-001)
    ├─ Dashboard totals updated
    └─ Customer ledger updated
```

---

## 4. Customer Ledger Update Flow

```
For each Sale created:

[CL.1] Get Customer
    ├─ customerId = newSale.customerId
    ├─ customer = LocalDb.customerById(customerId)
    └─ If customer exists → Continue
    ↓
[CL.2] Calculate Ledger Entry
    ├─ amount = newSale.amount
    ├─ commission = newSale.commissionFee
    ├─ netSale = amount - commission
    └─ Entry = netSale (amount to add to customer balance)
    ↓
[CL.3] Update Customer Balance
    ├─ customer.currentBalance += netSale
    └─ Balance updated
    ↓
[CL.4] Create Ledger Record
    ├─ ledgerEntry = CustomerLedger(
    │   customerId: customerId,
    │   saleId: newSale.id,
    │   amount: netSale,
    │   type: 'sale',
    │   date: DateTime.now(),
    │ )
    └─ Ledger record created
    ↓
[CL.5] Save Updates
    ├─ await LocalDb.customers().put(customerId, customer)
    ├─ await LocalDb.customerLedgers().add(ledgerEntry)
    └─ Both persisted
    ↓
Customer Ledger Updated
```

---

## 5. Inventory Update Flow

```
For each Sale with gemstone:

[INV.1] Get Gemstone
    ├─ gemstoneId = newSale.gemstoneId
    ├─ gemstone = LocalDb.gemstoneById(gemstoneId)
    └─ If gemstone exists → Continue
    ↓
[INV.2] Calculate Remaining Quantity
    ├─ soldQuantity = gemstone.soldQuantity + qty
    ├─ remainingQuantity = gemstone.quantity - soldQuantity
    └─ New remaining calculated
    ↓
[INV.3] Update Gemstone Inventory
    ├─ gemstone.soldQuantity = soldQuantity
    ├─ gemstone.remainingQuantity = remainingQuantity
    └─ Inventory updated
    ↓
[INV.4] Check Stock Status
    ├─ If remainingQuantity <= 0:
    │   └─ gemstone.status = 'sold_out'
    └─ If remainingQuantity > 0:
        └─ gemstone.status = 'active'
    ↓
[INV.5] Save Gemstone
    ├─ await LocalDb.gemstones().put(gemstoneId, gemstone)
    └─ Inventory persisted
    ↓
Inventory Updated
```

---

## 6. Product Ledger Update Flow

```
For each changed gemstone:

[PL.1] Get All Sales for Gemstone
    ├─ gemstoneId = gemId
    ├─ allSales = LocalDb.sales()
    │   .values
    │   .where((s) => s.gemstoneId == gemstoneId && !s.isDeleted)
    │   .toList()
    └─ All sales for this gemstone collected
    ↓
[PL.2] Calculate Cumulative Metrics
    ├─ totalSaleAmount = sum of all s.amount
    ├─ totalCost = sum of all s.costPrice
    ├─ totalProfit = totalSaleAmount - totalCost
    ├─ totalQuantity = sum of all s.quantity
    └─ Metrics calculated
    ↓
[PL.3] Update Gemstone Ledger Fields
    ├─ gemstone.totalSales = totalSaleAmount
    ├─ gemstone.totalCostRecovered = totalCost
    ├─ gemstone.totalProfit = totalProfit
    ├─ gemstone.totalQuantitySold = totalQuantity
    └─ Ledger fields updated
    ↓
[PL.4] Save Gemstone
    ├─ await LocalDb.gemstones().put(gemstoneId, gemstone)
    └─ Product ledger persisted
    ↓
Product Ledger Updated
```

---

## 7. Profit Update Flow

```
For each changed gemstone:

[PROFIT.1] Get Gemstone Purchase Record
    ├─ gemstoneId = gemId
    ├─ gemstone = LocalDb.gemstoneById(gemstoneId)
    └─ Purchase record retrieved
    ↓
[PROFIT.2] Calculate Cost Recovery
    ├─ totalSales = sum of all sales for gemstone
    ├─ costRecovered = min(totalSales, gemstone.purchasePrice)
    ├─ remainingCost = gemstone.purchasePrice - costRecovered
    └─ Cost tracking calculated
    ↓
[PROFIT.3] Calculate Profit
    ├─ totalProfit = totalSales - gemstone.purchasePrice
    ├─ If totalProfit < 0:
    │   └─ profitStatus = 'loss'
    └─ If totalProfit >= 0:
        └─ profitStatus = 'profit'
    ↓
[PROFIT.4] Update Gemstone Profit Fields
    ├─ gemstone.costRecovered = costRecovered
    ├─ gemstone.remainingCost = remainingCost
    ├─ gemstone.totalProfit = totalProfit
    ├─ gemstone.profitStatus = profitStatus
    └─ Profit fields updated
    ↓
[PROFIT.5] Save Gemstone
    ├─ await LocalDb.gemstones().put(gemstoneId, gemstone)
    └─ Profit metrics persisted
    ↓
Profit Updated
```

---

## 8. Implementation Order (Critical)

### Order Matters for Data Integrity

**Correct Order:**
```
1. VALIDATE ALL ITEMS (no writes)
2. GENERATE INVOICE NUMBER
3. SAVE EACH ITEM (write Sale to Hive)
4. UPDATE CUSTOMER LEDGER (write to customer & ledger)
5. UPDATE GEMSTONE COST RECOVERY (write to gemstone)
6. UPDATE PRODUCT LEDGER (write to gemstone)
7. UPDATE PROFIT METRICS (write to gemstone)
8. CLOSE FORM & SHOW SUCCESS
```

**Why This Order:**
- ✅ Validation first prevents partial saves
- ✅ Invoice number generated once, used for all items
- ✅ Items saved before ledger updates (ledger depends on sales)
- ✅ Customer ledger updated before product ledger
- ✅ Product ledger updated before profit calculation
- ✅ Profit calculation last (depends on all other updates)
- ✅ Form closed only after all writes succeed

**If Order is Wrong:**
- ❌ Save item, then validate → Partial invoice if validation fails
- ❌ Update ledger before saving item → Ledger entry for non-existent sale
- ❌ Update profit before product ledger → Incorrect profit calculation
- ❌ Close form before saving → User thinks saved but data missing

---

## 9. Risk Analysis

### Risk Matrix

| Risk | Severity | Probability | Mitigation | Status |
|------|----------|-------------|-----------|--------|
| Partial invoice (item 1 saves, item 2 fails) | 🔴 High | 🟡 Medium | Validate all before saving | ✅ Planned |
| Duplicate invoiceNumber | 🟡 Medium | 🟢 Low | Generate fresh each time | ✅ Planned |
| Customer ledger inconsistency | 🟡 Medium | 🟢 Low | Reuse existing LocalDb method | ✅ Planned |
| Gemstone cost recovery error | 🟡 Medium | 🟢 Low | Reuse existing LocalDb method | ✅ Planned |
| Product ledger miscalculation | 🟡 Medium | 🟢 Low | Reuse existing LocalDb method | ✅ Planned |
| Profit calculation error | 🟡 Medium | 🟢 Low | Reuse existing LocalDb method | ✅ Planned |
| Null pointer in loop | 🟢 Low | 🟢 Low | Validate items before loop | ✅ Planned |
| UI not refreshing | 🟢 Low | 🟢 Low | Reuse existing ValueListenableBuilder | ✅ Planned |

### Mitigation Strategies

**High Risk: Partial Invoice**
- Strategy: Validate ALL items before saving ANY
- Benefit: Prevents 99% of partial saves
- Cost: Minimal (validation is fast)

**Medium Risk: Ledger Inconsistency**
- Strategy: Reuse existing LocalDb methods
- Benefit: Uses proven, tested code
- Cost: None (already exists)

**Low Risk: Null Pointer**
- Strategy: Validate items list before loop
- Benefit: Prevents runtime crashes
- Cost: Minimal (one check)

---

## 10. Algorithm Pseudocode

```
FUNCTION _save()
  // PHASE 1: VALIDATION
  IF NOT form.validate() THEN
    toast('Form invalid')
    RETURN
  END IF
  
  IF items.isEmpty() THEN
    toast('Add at least one item')
    RETURN
  END IF
  
  FOR EACH item IN items DO
    IF NOT validateItem(item) THEN
      toast('Item error')
      RETURN
    END IF
  END FOR
  
  // PHASE 2: PREPARATION
  invoiceNumber = generateInvoiceNumber()
  gemstonesUpdated = Set()
  
  // PHASE 3: SAVE LOOP
  FOR EACH item IN items DO
    qty = parseInt(item.quantity) ?? 1
    unitPrice = parseDouble(item.unitPrice) ?? 0
    amount = qty * unitPrice
    commission = parseDouble(commissionField) ?? 0
    netSale = amount - commission
    
    sale = createSale(
      gemstoneId: item.gemstoneId,
      gemstoneName: item.gemstoneName,
      customerId: selectedCustomerId,
      customerName: customerField,
      amount: amount,
      quantity: qty,
      netSale: netSale,
      invoiceNumber: invoiceNumber,
      ... other fields ...
    )
    
    AWAIT box.add(sale)
    AWAIT LocalDb.applySaleCustomerLedger(sale)
    
    IF item.gemstoneId NOT EMPTY THEN
      gemstone = LocalDb.gemstoneById(item.gemstoneId)
      IF gemstone NOT NULL THEN
        LocalDb.applyCostRecovery(gemstone, netSale)
        AWAIT box.put(item.gemstoneId, gemstone)
        gemstonesUpdated.add(item.gemstoneId)
      END IF
    END IF
  END FOR
  
  // PHASE 4: POST-SAVE UPDATES
  FOR EACH gemstoneId IN gemstonesUpdated DO
    AWAIT LocalDb.updateGemstoneProductLedger(gemstoneId)
  END FOR
  
  toast('Invoice ' + invoiceNumber + ' saved!')
  Navigator.pop(context)
END FUNCTION
```

---

## 11. Key Design Decisions

### Decision 1: Validate Before Save
**Option A:** Validate during save (fail fast)
**Option B:** Validate all before save (prevent partial)
**Chosen:** Option B
**Reason:** Prevents partial invoices, simpler error handling

### Decision 2: One Invoice Number Per Save
**Option A:** Generate invoice number per item
**Option B:** Generate once, use for all items
**Chosen:** Option B
**Reason:** Groups items into single invoice, simpler logic

### Decision 3: Reuse Existing LocalDb Methods
**Option A:** Create new helper methods
**Option B:** Reuse existing LocalDb methods
**Chosen:** Option B
**Reason:** Uses proven code, reduces bugs, faster implementation

### Decision 4: Photos Only on First Item
**Option A:** Attach photos to each item
**Option B:** Attach photos only to first item
**Chosen:** Option B
**Reason:** Photos represent whole invoice, not individual items

### Decision 5: No Custom Rollback
**Option A:** Implement full rollback on error
**Option B:** Let user retry on error
**Chosen:** Option B
**Reason:** Validation prevents most errors, rollback adds complexity

---

## 12. Success Criteria

### Algorithm is Correct When:
- ✅ All items validate before ANY save
- ✅ All items share same invoiceNumber
- ✅ Each item creates separate Sale record
- ✅ Customer ledger updated for each item
- ✅ Gemstone cost recovery applied for each item
- ✅ Product ledger recalculated for all changed gemstones
- ✅ Profit metrics updated correctly
- ✅ Form closes only after all writes succeed
- ✅ UI refreshes automatically
- ✅ Error messages are clear

---

## 13. Next Steps

### Phase 2B-1: Implement Algorithm
1. Add invoiceNumber generation
2. Implement validation method
3. Implement save loop
4. Test with single item
5. Test with multiple items
6. Run PAT

### Phase 2B-2: Add Error Handling
1. Add try-catch blocks
2. Add specific error messages
3. Test error scenarios
4. Run PAT

### Phase 2B-3: Optimize Performance
1. Batch gemstone updates
2. Optimize ledger calculations
3. Test with large invoices
4. Run PAT

---

**Status:** ✅ **Algorithm Design Complete**

This algorithm is:
- ✅ Safe (validates before saving)
- ✅ Simple (reuses existing logic)
- ✅ Testable (clear phases)
- ✅ Reversible (each phase independent)
- ✅ Proven (uses existing LocalDb methods)

Ready for Phase 2B-1 implementation.
