# Sales Invoice Design Specification
## 1:1 Match with Broker Consignment Voucher

### Page Layout
- **Page Size (Widget):** 800×1100 px
- **Page Size (PDF):** A4 (210×297 mm)
- **Margins:** 20px all sides
- **Background:** White
- **Spacing Between Sections:** 12px

### Header Section
**Structure:**
```
[Logo 80×80] [Shop Name + Contact Info]
```

**Logo:**
- Size: 80×80 px (fixed)
- Loaded from business profile
- Fallback: omit if unavailable

**Shop Info Column:**
- Shop Name: 18pt bold, Padauk
- Subtitle: 14pt bold, Padauk (fixed text)
- Contact Info (conditional, 10pt):
  - Phone
  - Address
  - Email
  - Facebook
  - Viber
  - Website

### Meta Row
**Position:** Below header, 8px spacing
**Content:**
- Left: "ဘောင်ချာ နံပါတ်: {invoiceNumber}" (11pt)
- Right: "ရက်စွဲ: {formattedDate}" (11pt)
- Font: Padauk, regular

### Customer Info Box
**Position:** Below meta row, 12px spacing
**Style:**
- Border: 1px solid grey400
- Padding: 8px all sides
- Background: White

**Content:**
- Title: "ဖောက်သည်အချက်အလက်" (11pt bold)
- Spacing: 4px below title
- Content (10pt regular):
  - Gemstone types (comma-separated)
  - Total quantity
  - Unit (kg)
- Spacing: 4px
- Summary Row (3 columns):
  - Total Sale Amount (9pt)
  - Total Commission (9pt)
  - Total Net (9pt)

### Items Table
**Position:** Below customer box, 15px spacing
**Border:** 1px solid grey400 (all cells)
**Column Widths (Fixed):**
| No. | Column | Width | Content |
|-----|--------|-------|---------|
| 0 | ល.ដ | 25 | Item number |
| 1 | ပစ္စည်းအမည် | 80 | Gemstone name |
| 2 | အမျိုးအစား | 50 | Type (whole_stone) |
| 3 | အလေးချိန် | 40 | Weight + unit |
| 4 | အရေအတွက် | 45 | Quantity |
| 5 | ယူနစ်ဈေး | 40 | Unit price |
| 6 | ကော်မရှင် | 40 | Commission |
| 7 | စုစုပေါင်း | 40 | Total amount |

**Header Row:**
- Background: grey300
- Font: 9pt bold, Padauk
- Text Alignment: center
- Padding: 4px all sides

**Data Rows:**
- Font: 8pt regular, Padauk
- Text Alignment: center
- Padding: 4px all sides

**Totals Row:**
- Background: grey200
- Font: 9pt bold, Padauk
- Text Alignment: center
- Padding: 4px all sides
- Content:
  - Col 0: empty
  - Col 1: "စုစုပေါင်း"
  - Col 2-3: empty
  - Col 4: total quantity
  - Col 5: empty
  - Col 6: total commission
  - Col 7: total amount

### Footer Section
**Position:** Bottom of page, 15px spacing above
**Structure:** 3-column row
- Left: "ရေးထိုးသူ: __________" (9pt)
- Center: "စာမျက်နှာ {pageNum} / {totalPages}" (9pt)
- Right: "ကုန်သည် လက်မှတ်" (9pt)
- Font: Padauk, regular
- Text Alignment: left/center/right

### Font Specifications
- **Font Family:** Padauk (Myanmar support)
- **Regular Variant:** Padauk-Regular.ttf
- **Bold Variant:** Padauk-Bold.ttf
- **Asset Path:** assets/fonts/

### Color Specifications
- **Text:** Black (#000000)
- **Borders:** grey400 (#BDBDBD)
- **Header Background:** grey300 (#E0E0E0)
- **Totals Background:** grey200 (#EEEEEE)
- **Page Background:** White (#FFFFFF)

### Consistency Requirements
1. **PDF and Widget must be identical** in layout, spacing, fonts, colors
2. **Widget-based image export** (RepaintBoundary) - NOT PDF raster
3. **No business logic changes** - calculations, data structure unchanged
4. **All Myanmar text** must use Padauk font
5. **Column alignment** must be exact match with broker voucher

### Implementation Files
- `lib/core/services/voucher_export_service.dart` - PDF generation
- `lib/core/services/sales_invoice_image_widget.dart` - Widget rendering
- `lib/features/sales/presentation/pages/sales_page.dart` - Export triggers
