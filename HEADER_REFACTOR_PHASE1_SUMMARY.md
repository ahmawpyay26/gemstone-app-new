# Invoice Header Refactor - Phase 1 Summary

## Objective
Rebuild and optimize the Sales Invoice PNG export feature to match a specific professional design while maintaining existing PDF export functionality. The current focus is refactoring the header UI into a shared, standardized component.

## Completed Tasks

### 1. Created Shared Header Widget for PNG Export
**File:** `lib/core/services/invoice_header_widget.dart` (NEW)

A reusable Flutter widget that implements the standardized 6-row header layout:

```
Row 1: Shop Info (left) | Voucher Type (right)
Row 2: Voucher # (left) | Date (right)
Row 3: Source/Broker info (conditional)
Row 4: Customer info (conditional, with border)
Row 5: Summary box (with border)
Row 6: Item table (handled by parent)
```

**Features:**
- Renders shop logo, name, contact info
- Displays voucher type (own sale vs broker sale)
- Shows invoice number and date
- Conditional source/broker information
- Conditional customer details section
- Summary box with gemstone types, quantity, weight, and total value
- Supports both decoded logo (off-screen rendering) and file-based logo
- Myanmar text support via Padauk font

### 2. Created Standardized PDF Header Builder
**File:** `lib/core/services/voucher_export_service.dart`

Added method: `_buildStandardizedInvoiceHeader()`

A static method that generates the same 6-row header layout using PDF widgets (`pw.Widget`):
- Matches PNG layout exactly
- Uses PDF-compatible widget system
- Handles all conditional sections
- Supports logo rendering from bytes
- Maintains professional typography with Padauk font

### 3. Integrated Shared Header into PNG Export
**File:** `lib/core/services/sales_invoice_image_widget.dart`

**Changes:**
- Added import: `import 'invoice_header_widget.dart';`
- Replaced old header implementation with `InvoiceHeaderWidget`
- Removed redundant `_buildHeader()` method (commented out for reference)
- Removed redundant `_buildCustomerDetails()` method (commented out for reference)
- PNG export now uses standardized header (lines 73-77)

### 4. Integrated Standardized Header into PDF Export
**File:** `lib/core/services/voucher_export_service.dart`

**Changes:**
- Updated `generatePdfInvoiceBytes()` method
- Replaced old header implementation with `_buildStandardizedInvoiceHeader()`
- Removed 100+ lines of redundant old header code
- PDF export now uses standardized header (lines 942-948)

## Header Layout Specification

### Row 1: Shop Information
**Left Side:**
- Shop logo (60×60px for PDF, 80×80px for PNG)
- Shop name (bold, large)
- Subtitle: "ရောင်းချခြင်းဖောင်သည်အ"
- Contact info (phone, address, email - conditional)

**Right Side:**
- Label: "ဘောင်ချာအမျိုးအစား" (Voucher Type)
- Value: "ကိုယ်တိုင်ရောင်းချမှု" (Own Sale) OR "ပွဲစားထံမှ ရောင်းချမှု" (Broker Sale)

### Row 2: Identification
**Left:** Invoice number
**Right:** Date (formatted as dd/MM/yyyy in Myanmar locale)

### Row 3: Source Information (Conditional)
**Own Sale:**
- Label: "အရင်းအမြစ်"
- Value: "ကိုယ်တိုင်ရောင်းချမှု"

**Broker Sale:**
- Left: Source type ("ပွဲစားထံမှ ရောင်းချမှု")
- Right: Broker name

### Row 4: Customer Information (Conditional)
- Only shown if customer data exists
- Bordered container
- Shows customer name

### Row 5: Summary Box (Bordered)
- Gemstone types (comma-separated)
- Total quantity
- Total weight (in kg)
- Total value (formatted currency)

### Row 6: Item Table
- Unchanged from previous implementation
- Displays individual sale items
- Maintains existing column layout

## Data Source Analysis

**Sale Model Fields Used:**
- `invoiceNumber` - Voucher/Invoice number
- `saleDate` - Date (int timestamp)
- `brokerName` - Broker name (if broker sale)
- `customerName` - Customer name
- `customerId` - Customer reference
- `gemstoneName` - Gemstone type
- `quantity` - Item quantity
- `weightCarat` - Item weight
- `amount` - Total sale amount

**Sale Type Detection:**
- If `brokerName.isNotEmpty` → Broker Sale
- If `brokerName.isEmpty` → Own Sale

## Files Modified

| File | Changes | Lines |
|------|---------|-------|
| `invoice_header_widget.dart` | NEW - Flutter widget | 400+ |
| `sales_invoice_image_widget.dart` | Import + integrate header, comment old methods | 11, 119-300 |
| `voucher_export_service.dart` | Add PDF header builder, integrate into PDF export | 1150+, 942-948 |

## Backward Compatibility

- Old `_buildHeader()` and `_buildCustomerDetails()` methods in PNG widget are commented out (not deleted)
- Can be restored if needed for reference or debugging
- PDF export's old `_buildInvoiceHeader()` method remains unchanged (used elsewhere)
- No breaking changes to public APIs

## Testing Checklist

- [ ] PNG export renders with new header layout
- [ ] PDF export renders with new header layout
- [ ] Own sale invoices show correct voucher type
- [ ] Broker sale invoices show broker name
- [ ] Customer info appears when customer data exists
- [ ] Customer info hidden when no customer data
- [ ] Logo renders correctly in both PNG and PDF
- [ ] Myanmar text displays correctly
- [ ] Invoice number and date format correctly
- [ ] Summary box calculations are correct
- [ ] Table layout unchanged
- [ ] No compilation errors
- [ ] Flutter analyze passes
- [ ] GitHub Actions build succeeds
- [ ] PAT (Production Acceptance Testing) passes

## Next Steps

1. **Phase 2:** Verify both PNG and PDF exports produce identical header layouts
2. **Phase 3:** Test with various data scenarios (own sale, broker sale, with/without customer)
3. **Phase 4:** Optimize spacing and typography if needed
4. **Phase 5:** Full integration testing with real APK build
5. **Phase 6:** User acceptance testing

## Notes

- No business logic changes
- No database model changes
- No invoice calculation changes
- Purely UI refactoring for consistency
- Both PNG and PDF now share the same header structure
- Future maintenance: Any header changes need to be made in both widgets
