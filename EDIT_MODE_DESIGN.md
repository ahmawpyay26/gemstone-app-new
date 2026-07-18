# Broker Consignment Voucher Edit Flow — Design Document

## Edit Mode Parameters

When navigating from broker detail to edit form, pass these parameters:

```dart
// Navigation parameters (via GoRouter or context.push)
{
  'editVoucherId': String,           // UUID of the voucher group
  'editVoucherNumber': String,       // BC-YYYYMMDD-NNNN (must be preserved)
  'editBrokerName': String,
  'editBrokerPhone': String,
  'editBrokerAddress': String,
  'editBrokerSocial': String?,
  'editConsignmentDate': DateTime,
  'editNotes': String?,
  'editExistingItems': List<ConsignmentItemTemp>,  // Preload all items
  'editOriginalQuantities': Map<String, double>,   // For inventory safety
}
```

## Data Preload Strategy

### 1. Voucher Header Data
- Broker name, phone, address, social
- Consignment date
- Notes
- **Preserve existing voucher number** (do NOT regenerate)

### 2. Existing Items Preload
For each BrokerConsignment record with matching voucherId:
- Gemstone ID / name
- Source type (whole_stone or breakdown_item)
- Consigned quantity
- Breakdown item name (if breakdown_item)
- Photos
- Item ID (for update/delete tracking)

### 3. Inventory Safety State
Store original quantities for each item:
```dart
editOriginalQuantities: {
  'item_id_1': 3.0,  // Original consigned quantity
  'item_id_2': 2.5,
}
```

This enables:
```
effective_available = current_database_available + original_quantity - edited_quantity
```

## Form State Machine

### CREATE MODE
- Title: "ပွဲစားအပ်စာရင်း"
- Button: "သိမ်းဆည်းမည်"
- Generate new voucherId + voucherNumber
- Validation: normal inventory checks

### EDIT MODE
- Title: "ပွဲစားအပ်ဘောင်ချာ ပြုပြင်ရန်"
- Button: "ပြင်ဆင်မှု သိမ်းဆည်းမည်"
- Preserve existing voucherId + voucherNumber
- Validation: inventory checks with delta calculation

## Item Edit Tracking

Each ConsignmentItemTemp must track:
```dart
class ConsignmentItemTemp {
  String id;                    // Unique item ID (stable across edits)
  String? originalBcId;         // Original BrokerConsignment record ID (for updates)
  bool isNew;                   // true = new item, false = existing item
  bool isDeleted;               // true = marked for deletion
  double originalQuantity;      // Original consigned qty (for inventory delta)
  // ... existing fields
}
```

## Save Strategy

### Phase A: Validate
- Header fields not empty
- At least one item exists
- Quantities valid
- Inventory available (with delta calculation)

### Phase B: Compute Deltas
For each item:
- If isNew: delta = -edited_qty
- If isDeleted: delta = +original_qty
- If edited: delta = original_qty - edited_qty

### Phase C: Update Records
- Update existing BrokerConsignment records (preserve voucherId + voucherNumber)
- Add new BrokerConsignment records (use same voucherId + voucherNumber)
- Delete removed BrokerConsignment records

### Phase D: Update Inventory
- Apply quantity deltas to each purchase
- Recalculate remaining quantities

### Phase E: Return to Detail
- Pop with true to trigger refresh
- Detail page reloads voucher data

## Inventory Safety Example

Database state after original voucher:
- Gemstone A: remaining = 7

Original voucher:
- Gemstone A: consigned = 3

User edits to:
- Gemstone A: consigned = 4

Calculation:
```
effective_available = 7 + 3 - 4 = 6  ✓ Valid
```

User tries to edit to:
- Gemstone A: consigned = 11

Calculation:
```
effective_available = 7 + 3 - 11 = -1  ✗ Invalid
```

## Backward Compatibility

Old vouchers without optional fields:
- brokerSocial → empty string
- notes → empty string
- photos → empty list
- consignmentDate → use current date (or stored date if available)

No crash on null fields.
