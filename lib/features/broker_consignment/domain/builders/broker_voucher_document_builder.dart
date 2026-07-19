import 'package:gemstone_management/core/local/models.dart';
import '../models/broker_voucher_document.dart';
import '../../../../core/utils/weight_converter.dart';
import '../../../../core/utils/total_weight_calculator.dart';

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

    // Check if voucher has mixed weight units
    final units = voucherItems
        .where((i) => i.weight != null && i.weight! > 0 && i.weightUnit != null && i.weightUnit!.isNotEmpty)
        .map((i) => i.weightUnit!)
        .toList();
    final hasMixedUnits = units.isNotEmpty && !WeightConverter.areAllUnitsSame(units);

    // Build document items with calculated quantities
    final documentItems = <BrokerVoucherDocumentItem>[];
    for (int i = 0; i < voucherItems.length; i++) {
      final item = voucherItems[i];
      documentItems.add(
        BrokerVoucherDocumentItem(
          itemNumber: i + 1,
          itemName: item.historicalData.gemstoneType,
          sourceType: item.historicalData.sourceType,
          weight: item.weight,
          weightUnit: item.weightUnit,
          consignedQuantity: item.consignedQuantity,
          soldQuantity: item.soldQuantity,
          returnedQuantity: item.returnedQuantity,
          remainingQuantity: item.remainingQuantity,
          notes: item.notes.isEmpty ? null : item.notes,
          photoPaths: item.photoPaths,
          hasMixedUnits: hasMixedUnits,
        ),
      );
    }

    // Calculate totals using shared calculator
    // DIAGNOSTIC LOG START
    print('[BrokerVoucherDocumentBuilder] Voucher: $voucherNumber');
    print('[BrokerVoucherDocumentBuilder] voucherItems.length: ${voucherItems.length}');
    for (int i = 0; i < voucherItems.length; i++) {
      final item = voucherItems[i];
      print('[BrokerVoucherDocumentBuilder] Item $i: ${item.historicalData.gemstoneType}, weight=${item.weight}, unit=${item.weightUnit}');
    }
    // DIAGNOSTIC LOG END
    
    final weightResult = TotalWeightCalculator.calculateTotalWeight(voucherItems);
    final totalWeight = TotalWeightCalculator.getTotalWeightValue(weightResult);
    final totalWeightUnit = TotalWeightCalculator.getTotalWeightUnit(weightResult);
    
    // DIAGNOSTIC LOG START
    print('[BrokerVoucherDocumentBuilder] After calculation:');
    print('[BrokerVoucherDocumentBuilder] weightResult: $weightResult');
    print('[BrokerVoucherDocumentBuilder] totalWeight: $totalWeight');
    print('[BrokerVoucherDocumentBuilder] totalWeightUnit: $totalWeightUnit');
    // DIAGNOSTIC LOG END

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
      totalWeightKg: totalWeight,
      totalWeightUnit: totalWeightUnit,
    );
    
    // DIAGNOSTIC LOG START
    print('[BrokerVoucherDocumentBuilder] BrokerVoucherDocumentTotals created:');
    print('[BrokerVoucherDocumentBuilder] totals.totalWeightKg: ${totals.totalWeightKg}');
    print('[BrokerVoucherDocumentBuilder] totals.totalWeightUnit: ${totals.totalWeightUnit}');
    // DIAGNOSTIC LOG END

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
