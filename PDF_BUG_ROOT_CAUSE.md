# PDF Export Bug - Root Cause & Fix

## Issue
- User taps "PDF ထုတ်ရန်"
- Loading message appears
- Share Sheet NEVER appears
- No error shown

## Root Cause
**File:** `lib/core/services/voucher_export_service.dart`
**Method:** `_buildStandardizedInvoiceHeader()` (line 914)
**Line:** 943-945

The method accesses `profile.shopName` without null safety:
```dart
final shopName = profile.shopName.isNotEmpty
    ? profile.shopName
    : 'ပွဲစားအပ်နှံဘောင်ချာ';
```

If `profile` is null or `profile.shopName` is null, this throws NullPointerException.

The exception is caught in `generatePdfInvoice()` (line 698-702):
```dart
} catch (e, stackTrace) {
  developer.log('[VOUCHER_SERVICE] EXCEPTION in generatePdfInvoice: $e');
  developer.log('[VOUCHER_SERVICE] Stack trace: $stackTrace');
  print('Error generating PDF invoice: $e');
  return null;  // ← Returns null, so file == null in caller
}
```

The caller then sees `file == null` and doesn't call Share.shareXFiles().

## Fix Applied
**Line 943:** Added null safety operator
```dart
// BEFORE:
final shopName = profile.shopName.isNotEmpty
    ? profile.shopName
    : 'ပွဲစားအပ်နှံဘောင်ချာ';

// AFTER:
final shopName = (profile?.shopName?.isNotEmpty ?? false)
    ? profile.shopName
    : 'ပွဲစားအပ်နှံဘောင်ချာ';
```

This safely handles:
- `profile` being null
- `profile.shopName` being null
- `profile.shopName` being empty

## Additional Null Safety Checks Needed
Check for other unsafe property accesses in the method:
- Line 979: `profile.phone?.isNotEmpty == true` (already safe)
- Line 984: `profile.address?.isNotEmpty == true` (already safe)
- Line 989: `profile.email?.isNotEmpty == true` (already safe)

## Expected Result
After fix:
1. PDF generation will not throw exception
2. PDF file will be created successfully
3. Share.shareXFiles() will be called
4. Share Sheet will appear on device

## Testing
Test on physical device:
1. Go to Sales History
2. Select a sale
3. Tap "PDF ထုတ်ရန်"
4. Verify Share Sheet appears with valid PDF
