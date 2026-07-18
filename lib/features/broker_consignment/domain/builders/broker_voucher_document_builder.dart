import 'package:gemstone_management/core/local/models.dart';
import '../models/broker_voucher_document.dart';

/// Builds BrokerVoucherDocumentData from a list of grouped BrokerConsignment items
/// Ensures single source of truth for all export formats
class BrokerVoucherDocumentBuilder {
  /// Build document data from a grouped voucher (list of items with same voucherNumber)
  static BrokerVoucherDocumentData buildFromVoucher({
    required List<BrokerConsignment> voucherItems,
    required String voucherNumber,
    required int voucherDate,
  }) {
    if (voucherItems.isEmpty) {
      throw ArgumentError('Voucher must contain at least one item');
    }

    // Use first item for broker information (all items in voucher have same broker)
    final firstItem = voucherItems.first;

    // Build document items with calculated quantities
    final documentItems = <BrokerVoucherDocumentItem>[];
    for (int i = 0; i < voucherItems.length; i++) {
      final item = voucherItems[i];
      documentItems.add(
        BrokerVoucherDocumentItem(
          itemNumber: i + 1,
          itemName: item.historicalData.gemstoneType,
          sourceType: item.historicalData.sourceType,
          weight: item.historicalData.originalWeight,
          weightUnit: 'ကျပ်', // Fixed unit for Myanmar gemstones
          consignedQuantity: item.consignedQuantity,
          soldQuantity: item.soldQuantity,
          returnedQuantity: item.returnedQuantity,
          remainingQuantity: item.remainingQuantity,
          notes: item.notes.isEmpty ? null : item.notes,
          photoPaths: item.photoPaths,
        ),
      );
    }

    // Calculate totals
    final totals = BrokerVoucherDocumentTotals(
      distinctItemCount: voucherItems.length,
      totalConsignedQuantity: voucherItems.fold(
        0.0,
        (sum, item) => sum + item.consignedQuantity,
      ),
      totalSoldQuantity: voucherItems.fold(
        0.0,
        (sum, item) => sum + item.soldQuantity,
      ),
      totalReturnedQuantity: voucherItems.fold(
        0.0,
        (sum, item) => sum + item.returnedQuantity,
      ),
      totalRemainingQuantity: voucherItems.fold(
        0.0,
        (sum, item) => sum + item.remainingQuantity,
      ),
    );

    // Collect all unique photos from all items
    final allPhotos = <String>{};
    for (final item in voucherItems) {
      if (item.photoPaths.isNotEmpty) {
        allPhotos.addAll(
          item.photoPaths.where((path) => path.trim().isNotEmpty),
        );
      }
    }

    return BrokerVoucherDocumentData(
      voucherNumber: voucherNumber,
      voucherDate: voucherDate,
      brokerName: firstItem.brokerName,
      brokerPhone: firstItem.brokerPhone,
      brokerAddress: firstItem.brokerAddress.isEmpty ? null : firstItem.brokerAddress,
      notes: firstItem.notes.isEmpty ? null : firstItem.notes,
      items: documentItems,
      totals: totals,
      photoPaths: allPhotos.toList(),
    );
  }
}
