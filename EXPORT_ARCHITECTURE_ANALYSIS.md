# Export Architecture Analysis Report

## Executive Summary

The Gemstone App has **TWO SEPARATE** export systems:
1. **Own Sales System** - Direct customer sales (uses `Sale` model)
2. **Broker Consignment System** - Broker-managed sales (uses `BrokerConsignment` + `BrokerVoucherDocumentData`)

These are completely independent and use different models, services, and widgets.

---

## 1. Own Sales PNG Export

### Model
- **Model:** `Sale` (from `lib/core/local/models.dart`)
- **Fields Used:** `invoiceNumber`, `saleDate`, `gemstoneName`, `quantity`, `amount`, `commissionFee`, `customerName`, `customerId`, `weightCarat`, `weightUnit`, `paymentMethod`, `note`
- **Does NOT have:** `brokerName`, `saleType`, `sourceType`, `isBrokerSale`

### Service Chain
```
SalesInvoiceImageExporter
  ↓
SalesInvoicePngExporter
  ↓
_captureInvoiceAsImage()
  ↓
SalesInvoiceImageWidget.forPngExport()
```

### Widget
- **File:** `lib/core/services/sales_invoice_image_widget.dart`
- **Class:** `SalesInvoiceImageWidget`
- **Input:** `List<Sale> sales`
- **Renders:** PNG image of invoice using Flutter widgets

### Flow
```
User clicks "Export PNG" on Sales Page
  ↓
SalesInvoiceImageExporter.exportImageAndShare(List<Sale> sales)
  ↓
SalesInvoicePngExporter.exportImageAndShare(List<Sale> sales)
  ↓
_captureInvoiceAsImage(List<Sale> sales)
  ↓
Creates RepaintBoundary with SalesInvoiceImageWidget
  ↓
Renders to PNG via toImage()
  ↓
Shares PNG file
```

---

## 2. Own Sales PDF Export

### Model
- **Model:** `Sale` (from `lib/core/local/models.dart`)
- **Same fields as PNG export**

### Service
- **File:** `lib/core/services/voucher_export_service.dart`
- **Class:** `VoucherExportService`
- **Methods:**
  - `generatePdfVoucher(Sale sale)` - Single sale PDF
  - `generatePdfInvoice(List<Sale> sales)` - Multi-item invoice PDF
  - `generatePdfInvoiceBytes(List<Sale> sales)` - Returns Uint8List

### Flow
```
User clicks "Export PDF" on Sales Page
  ↓
VoucherExportService.generatePdfInvoice(List<Sale> sales)
  ↓
Uses pdf package (pw.Widget)
  ↓
Builds PDF with header, items table, footer
  ↓
Returns File or Uint8List
  ↓
Shares PDF file
```

### Header Implementation (Current)
- **Location:** `lib/core/services/voucher_export_service.dart` lines 942-948
- **Method:** `_buildStandardizedInvoiceHeader()`
- **Status:** ⚠️ **BROKEN** - References `sales.first.brokerName` which doesn't exist in Sale model

---

## 3. Broker Sales PNG Export

### Model
- **Model:** `BrokerVoucherDocumentData` (from `lib/features/broker_consignment/domain/models/broker_voucher_document.dart`)
- **Fields:** `voucherNumber`, `voucherDate`, `brokerName`, `brokerPhone`, `brokerAddress`, `items` (List<BrokerVoucherDocumentItem>), `totals`, `photoPaths`

### Service
- **File:** `lib/features/broker_consignment/domain/services/broker_voucher_image_exporter.dart`
- **Class:** `BrokerVoucherImageExporter`
- **Method:** `exportImageAndShare(BrokerVoucherDocumentData data, BuildContext context)`

### Widget
- **File:** Not found in current codebase
- **Status:** Broker PNG export exists but widget implementation is separate from own sales

### Flow
```
User exports Broker Voucher as PNG
  ↓
BrokerVoucherImageExporter.exportImageAndShare(BrokerVoucherDocumentData data)
  ↓
Renders BrokerVoucherDocumentData to PNG
  ↓
Shares PNG file
```

---

## 4. Broker Sales PDF Export

### Model
- **Model:** `BrokerVoucherDocumentData`
- **Same fields as Broker PNG export**

### Service
- **File:** `lib/features/broker_consignment/domain/services/broker_voucher_pdf_generator.dart`
- **Class:** `BrokerVoucherPdfGenerator`
- **Method:** `generatePdf(BrokerVoucherDocumentData data)`

### Header Implementation
- **Location:** `lib/features/broker_consignment/domain/services/broker_voucher_pdf_generator.dart` line 70
- **Method:** `_buildHeader(data, padaukRegular, padaukBold, logoBytes)`
- **Status:** ✅ **WORKING** - Uses `BrokerVoucherDocumentData` which has `brokerName`

### Flow
```
User exports Broker Voucher as PDF
  ↓
BrokerVoucherExportService.exportPdfAndShare(BrokerVoucherDocumentData data)
  ↓
BrokerVoucherPdfGenerator.generatePdf(BrokerVoucherDocumentData data)
  ↓
Builds PDF with header, broker info, items table
  ↓
Returns Uint8List
  ↓
Shares PDF file
```

---

## Export Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GEMSTONE APP EXPORT SYSTEM                          │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌──────────────────┐
                              │   Sales Page     │
                              │  (User Action)   │
                              └────────┬─────────┘
                                       │
                    ┌──────────────────┴──────────────────┐
                    │                                     │
        ┌───────────▼─────────────┐         ┌────────────▼──────────────┐
        │  Own Sales Export       │         │  Broker Sales Export      │
        │  (List<Sale>)           │         │  (BrokerVoucherDocData)   │
        └───────────┬─────────────┘         └────────────┬──────────────┘
                    │                                     │
        ┌───────────┴──────────┐                ┌────────┴────────┐
        │                      │                │                 │
    ┌───▼────┐            ┌───▼────┐      ┌───▼────┐        ┌───▼────┐
    │  PNG   │            │  PDF   │      │  PNG   │        │  PDF   │
    │Export  │            │Export  │      │Export  │        │Export  │
    └───┬────┘            └───┬────┘      └───┬────┘        └───┬────┘
        │                     │                │                 │
        │                     │                │                 │
    ┌───▼──────────┐      ┌───▼──────────┐    │            ┌────▼──────────┐
    │SalesInvoice  │      │VoucherExport │    │            │BrokerVoucher  │
    │ImageExporter │      │Service       │    │            │PdfGenerator   │
    │              │      │              │    │            │               │
    │• PNG Export  │      │• generatePdf │    │            │• generatePdf  │
    │• Uses Sale   │      │  Invoice()   │    │            │• Uses Broker  │
    │  model       │      │• Uses Sale   │    │            │  VoucherDoc   │
    │              │      │  model       │    │            │  Data         │
    └───┬──────────┘      └───┬──────────┘    │            └────┬──────────┘
        │                     │                │                 │
    ┌───▼──────────────┐  ┌───▼──────────────┐ │            ┌────▼──────────┐
    │SalesInvoiceImage │  │_buildStandardized│ │            │_buildHeader   │
    │Widget            │  │InvoiceHeader()   │ │            │               │
    │                  │  │                  │ │            │✅ WORKING     │
    │• Renders PNG     │  │⚠️ BROKEN         │ │            │Uses brokerName│
    │• Uses Sale model │  │References        │ │            │from Document  │
    │                  │  │brokerName (DNE)  │ │            │Data           │
    └──────────────────┘  └──────────────────┘ │            └───────────────┘
                                                │
                                          ┌─────▼──────────┐
                                          │BrokerVoucher   │
                                          │ImageExporter   │
                                          │                │
                                          │• PNG Export    │
                                          │• Uses Broker   │
                                          │  VoucherDoc    │
                                          │  Data          │
                                          └────────────────┘
```

---

## Critical Issues Found

### Issue 1: ⚠️ BROKEN Own Sales PDF Header
- **Location:** `lib/core/services/voucher_export_service.dart` lines 942-948
- **Problem:** `_buildStandardizedInvoiceHeader()` references `sales.first.brokerName`
- **Reality:** `Sale` model does NOT have `brokerName` field
- **Result:** **COMPILATION ERROR** - Code will not compile
- **Root Cause:** Assumption made during refactoring without checking Sale model

### Issue 2: ⚠️ Incorrect Logic in Header Widget
- **Location:** `lib/core/services/invoice_header_widget.dart`
- **Problem:** Same issue - references `brokerName` that doesn't exist
- **Result:** **COMPILATION ERROR** - Code will not compile

### Issue 3: ❌ Mixing Two Different Systems
- Own sales (Sale model) and Broker sales (BrokerVoucherDocumentData) are completely separate
- Attempting to add broker detection logic to own sales header is incorrect
- Own sales are NEVER broker sales

---

## Data Model Comparison

| Field | Sale Model | BrokerConsignment | BrokerVoucherDocumentData |
|-------|-----------|-------------------|---------------------------|
| invoiceNumber | ✅ Yes | ❌ No | ✅ voucherNumber |
| saleDate | ✅ Yes | ❌ No | ✅ voucherDate |
| brokerName | ❌ **NO** | ✅ Yes | ✅ Yes |
| customerName | ✅ Yes | ❌ No | ❌ No |
| gemstoneName | ✅ Yes | ❌ No | ✅ (in items) |
| amount | ✅ Yes | ❌ No | ✅ (in totals) |
| quantity | ✅ Yes | ❌ No | ✅ (in items) |
| weightCarat | ✅ Yes | ❌ No | ✅ (in items) |

---

## Correct Architecture

### Own Sales System (Current)
- **Model:** `Sale` (direct customer sales only)
- **PNG Export:** `SalesInvoiceImageWidget` ✅ Working
- **PDF Export:** `VoucherExportService._buildStandardizedInvoiceHeader()` ⚠️ **BROKEN**
- **Header Type:** Should NOT include broker information
- **Sale Type:** Always "Own Sale" (no broker)

### Broker Sales System (Current)
- **Model:** `BrokerVoucherDocumentData` (broker consignment only)
- **PNG Export:** `BrokerVoucherImageExporter` ✅ Working
- **PDF Export:** `BrokerVoucherPdfGenerator._buildHeader()` ✅ Working
- **Header Type:** Should include broker information
- **Sale Type:** Always "Broker Sale"

---

## Recommendations

### For Own Sales Header Refactor (Phase 1)

1. **Remove** `brokerName` references from:
   - `lib/core/services/invoice_header_widget.dart`
   - `lib/core/services/voucher_export_service.dart`

2. **Own Sales Header Should Display:**
   - Row 1: Shop info + logo (left) | "ကိုယ်တိုင်ရောင်းချမှု" (right)
   - Row 2: Invoice # (left) | Date (right)
   - Row 3: (Optional) Source indicator
   - Row 4: Customer info (if exists)
   - Row 5: Summary box

3. **DO NOT:**
   - Add broker detection logic
   - Reference non-existent fields
   - Mix own sales with broker sales logic

### For Broker Sales (Future Phase)

- Broker sales already have separate export system
- No changes needed for broker sales in this phase
- Broker header already works correctly

---

## Files Affected

| File | Issue | Status |
|------|-------|--------|
| `lib/core/services/invoice_header_widget.dart` | References brokerName (DNE) | ⚠️ BROKEN |
| `lib/core/services/sales_invoice_image_widget.dart` | Uses InvoiceHeaderWidget | ⚠️ BROKEN |
| `lib/core/services/voucher_export_service.dart` | _buildStandardizedInvoiceHeader() broken | ⚠️ BROKEN |
| `lib/features/broker_consignment/domain/services/broker_voucher_pdf_generator.dart` | Broker PDF header | ✅ OK |
| `lib/features/broker_consignment/domain/services/broker_voucher_image_exporter.dart` | Broker PNG export | ✅ OK |

---

## Next Steps

1. **STOP** current refactoring
2. **FIX** broken references to `brokerName`
3. **VERIFY** Sale model fields actually available
4. **REWRITE** header logic for own sales only
5. **TEST** PNG export
6. **TEST** PDF export
7. **VERIFY** no compilation errors
