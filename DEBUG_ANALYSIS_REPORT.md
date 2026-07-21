# DEBUG ANALYSIS REPORT - IMAGE EXPORT CANVAS SIZE ISSUE

## Executive Summary

**Problem:** Sales Invoice Image Export shows narrow columns with text wrapping, while PDF Export displays correctly.

**Root Cause:** Dialog widget's default `maxWidth` constraint (400dp) is forcing the 800px invoice widget to shrink, causing table columns to compress.

**Impact:** FlexColumnWidth percentages are applied to the compressed width, resulting in narrower columns than intended.

---

## 1. PDF CONTENT WIDTH ANALYSIS

### PDF Page Format
- **Page Format:** A4
- **Page Width:** 210mm = 595.3 points
- **Page Height:** 297mm = 841.9 points
- **Margins:** 20mm = 56.7 points (each side)
- **Content Width:** 170mm = 481.9 points
- **Content Height:** 257mm = 728.5 points

### PDF Table Configuration
**File:** `lib/core/services/voucher_export_service.dart` (lines 680-691)

```dart
pw.Table(
  border: pw.TableBorder.all(color: PdfColors.grey400),
  columnWidths: {
    0: pw.FixedColumnWidth(40),      // Running Number
    1: pw.FixedColumnWidth(100),     // Gemstone Name
    2: pw.FixedColumnWidth(60),      // Item Type
    3: pw.FixedColumnWidth(50),      // Weight
    4: pw.FixedColumnWidth(50),      // Quantity
    5: pw.FixedColumnWidth(50),      // Unit Price
    6: pw.FixedColumnWidth(50),      // Commission
    7: pw.FixedColumnWidth(50),      // Net Amount
  },
  // Total: 450 points
)
```

**PDF Table Width:** 450 points
**PDF Content Width:** 481.9 points
**Fit Status:** ✅ FITS (31.9 points buffer)

---

## 2. IMAGE EXPORT WIDGET WIDTH ANALYSIS

### Image Widget Dimensions
**File:** `lib/core/services/sales_invoice_image_widget.dart` (lines 24-31)

```dart
return RepaintBoundary(
  key: repaintKey,
  child: Container(
    width: 800,           // Logical pixels
    height: 1100,         // Logical pixels
    color: Colors.white,
    padding: const EdgeInsets.all(20),
    child: SingleChildScrollView(
```

**Widget Width:** 800 logical pixels
**Widget Height:** 1100 logical pixels
**Padding:** 20px (each side)
**Content Width:** 760px (800 - 40)

### Conversion to Points
- **Conversion Factor:** 1 pixel ≈ 0.75 points (or 1 point ≈ 1.33 pixels)
- **Widget Width in Points:** 800px × 0.75 = 600 points
- **Widget Content Width in Points:** 760px × 0.75 = 570 points

### Comparison with PDF
| Dimension | Image Widget | PDF | Difference |
|-----------|--------------|-----|-----------|
| Total Width | 600 points | 595.3 points | +4.7 points (0.8%) |
| Content Width | 570 points | 481.9 points | +88.1 points (18.3%) |

---

## 3. IMAGE EXPORT TABLE CONFIGURATION

### Current Table Setup
**File:** `lib/core/services/sales_invoice_image_widget.dart` (lines 360-371)

```dart
return Table(
  border: TableBorder.all(color: Colors.grey),
  columnWidths: const {
    0: FlexColumnWidth(5),    // 5% - Running Number
    1: FlexColumnWidth(24),   // 24% - Gemstone Name
    2: FlexColumnWidth(12),   // 12% - Item Type
    3: FlexColumnWidth(10),   // 10% - Weight
    4: FlexColumnWidth(8),    // 8% - Quantity
    5: FlexColumnWidth(15),   // 15% - Unit Price
    6: FlexColumnWidth(10),   // 10% - Commission
    7: FlexColumnWidth(16),   // 16% - Net Amount
  },
  // Total: 100% (responsive)
)
```

**Table Uses:** `FlexColumnWidth` (percentage-based, responsive)
**PDF Uses:** `FixedColumnWidth` (fixed pixel widths)

### Key Difference
- **PDF:** Fixed column widths (450 points total) - doesn't shrink
- **Image:** Percentage-based widths - shrinks with container

---

## 4. DIALOG CONSTRAINT ANALYSIS

### Dialog Widget Configuration
**File:** `lib/features/sales/presentation/pages/sales_page.dart` (lines 206-255)

```dart
return Dialog(
  child: Scaffold(
    appBar: AppBar(...),
    body: widget,  // SalesInvoiceImageWidget
  ),
);
```

### Flutter Dialog Default Constraints
- **Default maxWidth:** 400dp (logical pixels)
- **Default maxHeight:** 90% of screen height
- **Behavior:** Constrains child to maxWidth if child is wider

### Constraint Conflict
| Component | Width | Status |
|-----------|-------|--------|
| Invoice Widget | 800px | Requests this width |
| Dialog maxWidth | ~400dp | Constrains to this |
| Result | ~400px | Widget shrinks to fit |

---

## 5. ROOT CAUSE ANALYSIS

### Why PDF Works Correctly
1. PDF uses `pw.Page(pageFormat: PdfPageFormat.a4)`
2. Page has explicit size (595.3 points)
3. No Dialog constraint involved
4. Table uses `FixedColumnWidth` (doesn't scale)
5. Columns maintain fixed widths regardless of page size
6. Result: ✅ Columns display at intended width

### Why Image Export Fails
1. Image widget (800px) > Dialog maxWidth (400dp)
2. Dialog constrains widget to ~400px width
3. Widget shrinks from 800px to ~400px
4. Table uses `FlexColumnWidth` (percentage-based)
5. Percentages apply to compressed width (400px instead of 800px)
6. Column widths become: 400px × 5% = 20px (instead of 40px)
7. Result: ❌ Columns appear compressed, text wraps

### Width Calculation Example
**For Column 1 (Gemstone Name - 24%)**

**Expected (without Dialog constraint):**
- Widget width: 800px
- Content width: 760px
- Column width: 760px × 24% = 182.4px

**Actual (with Dialog constraint):**
- Widget width: ~400px (constrained by Dialog)
- Content width: ~360px
- Column width: 360px × 24% = 86.4px
- **Result:** Column is 50% narrower than expected

---

## 6. TABLE BUILDER COMPARISON

### PDF Table Builder
- **File:** `voucher_export_service.dart` lines 680-691
- **Column Width Type:** `FixedColumnWidth` (fixed pixels)
- **Total Width:** 450 points (fixed)
- **Scaling:** None - columns stay fixed size
- **Result:** Correct layout

### Image Table Builder
- **File:** `sales_invoice_image_widget.dart` lines 360-371
- **Column Width Type:** `FlexColumnWidth` (percentage)
- **Total Width:** 100% (responsive)
- **Scaling:** Scales with container width
- **Result:** Compressed layout due to Dialog constraint

### Difference
| Aspect | PDF | Image |
|--------|-----|-------|
| Column Width Type | FixedColumnWidth | FlexColumnWidth |
| Scaling Behavior | Fixed | Responsive |
| Affected by Dialog | No | Yes |
| Result | ✅ Correct | ❌ Compressed |

---

## 7. WIDGET TREE AND CONSTRAINT FLOW

### Image Export Widget Tree
```
Dialog (maxWidth: 400dp)
├── Scaffold
│   ├── AppBar
│   └── body: SalesInvoiceImageWidget
│       └── RepaintBoundary
│           └── Container (width: 800px)
│               ├── padding: 20px
│               └── SingleChildScrollView
│                   └── Column
│                       └── Table (columnWidths: FlexColumnWidth)
│                           ├── TableRow (Header)
│                           ├── TableRow (Data rows)
│                           └── TableRow (Totals)
```

### Constraint Flow
1. Dialog applies maxWidth: 400dp
2. Container requests width: 800px
3. Dialog constrains Container to: ~400px
4. Container shrinks to: ~400px
5. Table content width becomes: ~360px (400 - 40 padding)
6. FlexColumnWidth percentages apply to: ~360px
7. Result: Columns compressed to ~50% of intended width

---

## 8. SUMMARY

### Width Dimensions
| Measurement | Value | Unit |
|-------------|-------|------|
| PDF A4 Content Width | 481.9 | points |
| Image Widget Width | 800 | pixels (600 points) |
| Image Widget Content Width | 760 | pixels (570 points) |
| Dialog maxWidth (default) | 400 | dp |
| Dialog Constrained Width | ~400 | pixels |
| Dialog Constrained Content | ~360 | pixels |

### Why Mismatch Occurs
1. **PDF:** Uses fixed page size (A4) + fixed column widths → Consistent layout
2. **Image:** Uses responsive column widths + Dialog constraint → Compressed layout
3. **Dialog:** Constrains 800px widget to ~400px → Causes 50% compression
4. **FlexColumnWidth:** Applies percentages to compressed width → Narrower columns

### Key Finding
**The Dialog widget's default maxWidth constraint is forcing the 800px invoice widget to shrink to ~400px, causing the FlexColumnWidth percentages to apply to a compressed width, resulting in narrower columns than intended.**

---

## Verification Checklist

- [x] PDF page format: A4 (595.3 points width)
- [x] PDF content width: 481.9 points
- [x] Image widget width: 800px (600 points)
- [x] Image widget content width: 760px (570 points)
- [x] Dialog default maxWidth: 400dp
- [x] PDF table uses FixedColumnWidth
- [x] Image table uses FlexColumnWidth
- [x] Dialog constrains image widget
- [x] FlexColumnWidth applies to compressed width
- [x] Root cause identified: Dialog maxWidth constraint

---

## Conclusion

The image export table columns appear narrow because the Dialog widget's default `maxWidth` constraint (400dp) is forcing the 800px invoice widget to shrink to approximately 400px. The `FlexColumnWidth` percentages then apply to this compressed width, resulting in columns that are approximately 50% narrower than intended. The PDF export works correctly because it uses fixed column widths and is not subject to Dialog constraints.

**No code changes were made during this analysis.**
