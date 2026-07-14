# Phase C - Grouped Voucher History UI Implementation Plan

**Status:** Pre-Implementation Investigation  
**Date:** Jul 14, 2026  
**Commit:** 215f0b9 (Phase B Correction)

---

## 1. CURRENT STATE ANALYSIS

### 1.1 Current Broker Consignment History UI

**File:** `lib/features/broker_consignment/presentation/pages/broker_consignment_page.dart`

**Current Structure:**
- **List View:** Flat list of individual `BrokerConsignment` records
- **Sorting:** Newest first (by `createdAt`)
- **Filtering:** By status (All, Active, Completed, Partial Return)
- **Summary Dashboard:** Aggregate totals from all records
- **Per-Item Card:** Each card shows:
  - Item name / purchase name
  - Date created
  - Status badge (Active/Partial Return/Completed)
  - Broker name
  - Quantities (consigned, sold, remaining, returned)
  - Inline return quantity input
  - Action menu (edit, delete, print, export, view photos)
- **No Grouping:** Currently treats each record independently

### 1.2 Data Model

**File:** `lib/core/local/models.dart`

**BrokerConsignment Fields:**
```dart
class BrokerConsignment {
  String id;                          // Unique per-item ID
  String purchaseId;                  // Reference to purchase
  
  // ✅ NEW FIELDS (Phase B)
  String? voucherId;                  // UUID - groups items
  String? voucherNumber;              // BC-YYYYMMDD-NNNN - human-readable
  
  // Status
  double consignedQuantity;
  double soldQuantity;
  double returnedQuantity;
  
  // Broker Info
  String brokerName;
  String brokerPhone;
  String brokerAddress;
  String? brokerSocialAccount;
  
  // Metadata
  BrokerHistoricalData historicalData;
  String notes;
  List<String> photoPaths;
  int createdAt;
  int updatedAt;
  int? deletedAt;
}
```

**Key Points:**
- ✅ `voucherId` and `voucherNumber` already exist (nullable)
- ✅ Backward compatible (old records have null values)
- ✅ Each record still has its own `id`, `purchaseId`, quantities, photos
- ✅ Multiple items can share same `voucherId` and `voucherNumber`

### 1.3 Database Access Layer

**File:** `lib/core/local/local_db.dart`

**Current Helpers:**
- `getAllActiveBrokerConsignments()` - Returns flat list, no grouping
- `createBrokerConsignment()` - Creates single record with voucher fields
- `processBrokerReturn()` - Operates on single record
- `deleteBrokerConsignment()` - Operates on single record
- `generateNextVoucherNumber()` - Generates BC-YYYYMMDD-NNNN (Phase B)

**Missing:**
- No voucher-level aggregate queries
- No batch return/delete by voucher
- No voucher grouping helper

---

## 2. PHASE C REQUIREMENTS

### 2.1 UI Changes

**From:** Item-level history list  
**To:** Grouped voucher history with expandable items

**Key Changes:**
1. Group records by `voucherNumber` (when not null)
2. Display voucher header with:
   - Voucher number (BC-YYYYMMDD-NNNN)
   - Voucher date (from first item's createdAt)
   - Broker name (shared by all items in voucher)
   - Aggregate quantities (sum of all items in voucher)
   - Aggregate status
3. Expandable/collapsible item list under each voucher
4. Individual item cards within each voucher group
5. Backward compatibility: Old records (null voucherId) displayed as individual cards

### 2.2 User Interactions

**Grouped Voucher Card:**
- Tap to expand/collapse items
- Show/hide individual items
- Voucher-level actions:
  - View all photos from all items
  - Print voucher summary
  - Export voucher details
  - Bulk return (return all items at once)

**Individual Item Card (within voucher):**
- Tap to view full details
- Per-item return quantity input
- Per-item actions (edit, delete, view photos)

**Legacy Items (null voucherId):**
- Display as before (individual cards)
- No grouping applied

---

## 3. DATABASE IMPACT

### 3.1 Schema Changes
**Required:** NONE

- Voucher fields already exist in `BrokerConsignment` model
- Hive adapter already reads/writes voucher fields
- No migration needed

### 3.2 Data Integrity
**No Changes Required:**
- Each record maintains its own `id`, `purchaseId`, quantities
- Voucher fields are purely organizational (UI grouping)
- Deleting one item in a voucher does NOT affect others
- Returning quantity from one item does NOT affect others
- Broker information is duplicated per item (no normalization needed)

### 3.3 Backward Compatibility
**Fully Compatible:**
- Old records with `null` voucherId and `voucherNumber` remain unchanged
- New records have voucher fields populated
- UI can handle both grouped and ungrouped records
- No data migration required
- No breaking changes to existing records

---

## 4. IMPLEMENTATION STRATEGY

### 4.1 Query Layer Changes

**New Helper in `local_db.dart`:**

```dart
/// Group active broker consignments by voucherId
/// Returns Map<String?, List<BrokerConsignment>>
/// null key = ungrouped records (old data)
static Map<String?, List<BrokerConsignment>> getGroupedBrokerConsignments() {
  final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
  final active = brokers.values.where((b) => b.isActive).toList();
  
  final grouped = <String?, List<BrokerConsignment>>{};
  for (final bc in active) {
    final key = bc.voucherNumber; // null for old records
    grouped.putIfAbsent(key, () => []).add(bc);
  }
  
  // Sort groups by newest first (use first item's createdAt)
  final sorted = grouped.entries.toList()
    ..sort((a, b) => (b.value.first.createdAt)
        .compareTo(a.value.first.createdAt));
  
  return Map.fromEntries(sorted);
}
```

### 4.2 UI Layer Changes

**File:** `broker_consignment_page.dart`

**Changes:**
1. Replace flat list with grouped list
2. Add voucher header widget
3. Add expandable item list widget
4. Update filtering logic for grouped view
5. Update summary calculations (same as before)

**New Widgets:**
- `_VoucherGroupCard()` - Displays voucher header + expandable items
- `_LegacyItemCard()` - Displays ungrouped items (old records)
- `_VoucherItemCard()` - Displays individual item within voucher

### 4.3 Action Handling

**Voucher-Level Actions:**
- Bulk return: Show dialog to return all items at once
- View all photos: Combine photos from all items
- Print/Export: Include all items in voucher

**Item-Level Actions:**
- Return: Per-item return quantity input (existing)
- Delete: Delete single item (existing)
- Edit: Edit single item (existing)

---

## 5. WIREFRAME / MOCKUP

### 5.1 Current State (Before Phase C)

```
┌─────────────────────────────────────────┐
│ ပွဲစားအပ်စာရင်းများ              [+]  │
├─────────────────────────────────────────┤
│ Summary Dashboard                       │
│ ┌───────────────────────────────────┐   │
│ │ 📦 Total Records: 15              │   │
│ │ 💎 Gemstones: 8                   │   │
│ │ 🔢 Total Consigned: 125           │   │
│ │ 💰 Total Sold: 45                 │   │
│ │ 📥 Total Returned: 20             │   │
│ │ 📦 Remaining: 60                  │   │
│ └───────────────────────────────────┘   │
├─────────────────────────────────────────┤
│ Filters: [All] [Active] [Completed]    │
├─────────────────────────────────────────┤
│ ITEM CARD 1                             │
│ ┌───────────────────────────────────┐   │
│ │ 🤝 Ruby / Whole Stone             │   │
│ │    Date: 14/07/2026               │   │
│ │    Status: [Active]               │   │
│ │ Broker: Aung Kyaw                 │   │
│ │ Consigned: 10 | Sold: 3           │   │
│ │ Returned: 0  | Remaining: 7       │   │
│ │ Return: [____] [Process]          │   │
│ │ [Menu ⋮]                          │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ITEM CARD 2                             │
│ ┌───────────────────────────────────┐   │
│ │ 🤝 Sapphire / Fragment            │   │
│ │    Date: 14/07/2026               │   │
│ │    Status: [Completed]            │   │
│ │ Broker: Aung Kyaw                 │   │
│ │ Consigned: 8 | Sold: 8            │   │
│ │ Returned: 0  | Remaining: 0       │   │
│ │ [Menu ⋮]                          │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ... more item cards ...                 │
└─────────────────────────────────────────┘
```

### 5.2 Phase C State (After Implementation)

```
┌─────────────────────────────────────────┐
│ ပွဲစားအပ်စာရင်းများ              [+]  │
├─────────────────────────────────────────┤
│ Summary Dashboard                       │
│ ┌───────────────────────────────────┐   │
│ │ 📦 Total Records: 15              │   │
│ │ 💎 Gemstones: 8                   │   │
│ │ 🔢 Total Consigned: 125           │   │
│ │ 💰 Total Sold: 45                 │   │
│ │ 📥 Total Returned: 20             │   │
│ │ 📦 Remaining: 60                  │   │
│ └───────────────────────────────────┘   │
├─────────────────────────────────────────┤
│ Filters: [All] [Active] [Completed]    │
├─────────────────────────────────────────┤
│ VOUCHER GROUP CARD (NEW)                │
│ ┌───────────────────────────────────┐   │
│ │ 🎫 BC-20260714-0001               │   │
│ │    Date: 14/07/2026 | Aung Kyaw   │   │
│ │ ─────────────────────────────────  │   │
│ │ Consigned: 18 | Sold: 11          │   │
│ │ Returned: 0   | Remaining: 7      │   │
│ │ Status: [Active] [▼ Expand]       │   │
│ │ [Photos] [Print] [Export] [Menu ⋮]│   │
│ └───────────────────────────────────┘   │
│   ├─ ITEM 1 (Ruby / Whole Stone)       │
│   │  ┌─────────────────────────────┐   │
│   │  │ Consigned: 10 | Sold: 3     │   │
│   │  │ Returned: 0 | Remaining: 7  │   │
│   │  │ Return: [____] [Process]    │   │
│   │  │ [Menu ⋮]                    │   │
│   │  └─────────────────────────────┘   │
│   │                                     │
│   └─ ITEM 2 (Sapphire / Fragment)      │
│      ┌─────────────────────────────┐   │
│      │ Consigned: 8 | Sold: 8      │   │
│      │ Returned: 0 | Remaining: 0  │   │
│      │ [Menu ⋮]                    │   │
│      └─────────────────────────────┘   │
│                                         │
│ VOUCHER GROUP CARD (NEW)                │
│ ┌───────────────────────────────────┐   │
│ │ 🎫 BC-20260714-0002               │   │
│ │    Date: 14/07/2026 | Zaw Min     │   │
│ │ ─────────────────────────────────  │   │
│ │ Consigned: 25 | Sold: 15          │   │
│ │ Returned: 5   | Remaining: 5      │   │
│ │ Status: [Partial Return] [▼ Expand]│   │
│ │ [Photos] [Print] [Export] [Menu ⋮]│   │
│ └───────────────────────────────────┘   │
│   ├─ ITEM 1 (Emerald / Whole Stone)    │
│   │  ...                                │
│   │                                     │
│   └─ ITEM 2 (Tourmaline / Fragment)    │
│      ...                                │
│                                         │
│ LEGACY ITEM CARD (Old Records)          │
│ ┌───────────────────────────────────┐   │
│ │ 🤝 Diamond / Whole Stone          │   │
│ │    Date: 13/07/2026               │   │
│ │    Status: [Completed]            │   │
│ │ Broker: Kyaw Soe                  │   │
│ │ Consigned: 5 | Sold: 5            │   │
│ │ Returned: 0  | Remaining: 0       │   │
│ │ [Menu ⋮]                          │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ... more voucher groups and legacy ...  │
└─────────────────────────────────────────┘
```

---

## 6. IMPLEMENTATION PHASES

### Phase C.1: Query Layer
- Add `getGroupedBrokerConsignments()` helper
- Add `getBrokerConsignmentsByVoucher(voucherNumber)` helper
- Add `getVoucherSummary(voucherId)` helper

### Phase C.2: UI Widgets
- Create `_VoucherGroupCard()` widget
- Create `_VoucherItemCard()` widget
- Create `_LegacyItemCard()` widget
- Create expandable/collapsible logic

### Phase C.3: List Integration
- Replace flat list with grouped list
- Update filtering logic
- Update sorting logic
- Handle mixed grouped/ungrouped records

### Phase C.4: Actions
- Implement voucher-level return (bulk)
- Implement voucher-level photo viewer
- Update print/export for vouchers
- Keep item-level actions intact

### Phase C.5: Testing
- Test grouped display
- Test filtering with groups
- Test legacy record display
- Test expand/collapse
- Test bulk actions

---

## 7. BACKWARD COMPATIBILITY

### 7.1 Data Migration
**Required:** NO

- Old records with null `voucherId`/`voucherNumber` remain unchanged
- New records have voucher fields populated
- No schema changes
- No data transformation needed

### 7.2 UI Handling
**Strategy:**
- Old records displayed as individual cards (no grouping)
- New records displayed in voucher groups
- Mixed list shows both grouped and ungrouped records
- Filtering works on both types

### 7.3 Actions
**Preserved:**
- All existing per-item actions work unchanged
- Return, delete, edit on individual items
- Summary calculations same as before
- No breaking changes

---

## 8. DATABASE MIGRATION IMPACT

### 8.1 Schema Changes
**None Required**

- Voucher fields already in model
- Hive adapter already handles them
- No migration script needed

### 8.2 Data Integrity
**No Risk:**
- Grouping is UI-only
- Each record maintains independence
- Deleting one item doesn't affect others
- No foreign key constraints
- No referential integrity issues

### 8.3 Performance Considerations
**Query Performance:**
- Current: O(n) flat list
- New: O(n) with grouping in memory
- No database query changes
- Grouping done in Dart (fast)

**Memory Usage:**
- Minimal increase (grouping metadata)
- Same number of records loaded
- No additional data stored

---

## 9. RISK ASSESSMENT

### 9.1 Low Risk
✅ No schema changes  
✅ No data migration  
✅ Backward compatible  
✅ UI-only changes  
✅ Existing actions preserved  

### 9.2 Medium Risk
⚠️ Grouping logic complexity  
⚠️ Expand/collapse state management  
⚠️ Filtering with groups  

### 9.3 Mitigation
- Comprehensive testing of grouping logic
- Clear separation of grouped vs. ungrouped records
- Preserve all existing actions
- Gradual rollout (test with small dataset first)

---

## 10. TESTING STRATEGY

### 10.1 Unit Tests
- `getGroupedBrokerConsignments()` grouping logic
- Null voucher handling
- Sorting within groups
- Aggregate calculations

### 10.2 Widget Tests
- Voucher group card rendering
- Expand/collapse functionality
- Item card rendering within groups
- Legacy card rendering

### 10.3 Integration Tests
- Full list with mixed records
- Filtering with groups
- Actions on grouped items
- Actions on legacy items

### 10.4 Manual Testing
- UI appearance and layout
- Expand/collapse responsiveness
- Filtering accuracy
- Bulk actions
- Legacy record display

---

## 11. DELIVERABLES

### Phase C.1
- [ ] `getGroupedBrokerConsignments()` helper
- [ ] `getBrokerConsignmentsByVoucher()` helper
- [ ] Query layer tests

### Phase C.2
- [ ] `_VoucherGroupCard()` widget
- [ ] `_VoucherItemCard()` widget
- [ ] `_LegacyItemCard()` widget
- [ ] Widget tests

### Phase C.3
- [ ] Updated `broker_consignment_page.dart`
- [ ] Grouped list rendering
- [ ] Filtering logic
- [ ] Integration tests

### Phase C.4
- [ ] Bulk return action
- [ ] Voucher photo viewer
- [ ] Print/export for vouchers
- [ ] Action tests

### Phase C.5
- [ ] Full integration testing
- [ ] Manual QA
- [ ] Documentation
- [ ] Commit and push

---

## 12. NOTES

- **No code changes yet** - This is planning only
- **Awaiting approval** - User must review and approve before implementation
- **Backward compatible** - Old records work unchanged
- **Zero migration risk** - No data transformation needed
- **UI-focused** - Changes are presentation layer only

---

**Next Step:** Await user approval to proceed with Phase C.1 implementation
