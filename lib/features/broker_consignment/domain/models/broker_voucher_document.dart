/// Shared immutable presentation model for broker voucher exports
/// Used consistently by Print, PDF, and Image Export features
/// Ensures single source of truth for all voucher output formats

class BrokerVoucherDocumentData {
  final String voucherNumber;
  final int voucherDate; // milliseconds since epoch
  final String brokerName;
  final String brokerPhone;
  final String? brokerAddress;
  final String? notes;
  final List<BrokerVoucherDocumentItem> items;
  final BrokerVoucherDocumentTotals totals;
  final List<String> photoPaths; // All unique photos from all items

  BrokerVoucherDocumentData({
    required this.voucherNumber,
    required this.voucherDate,
    required this.brokerName,
    required this.brokerPhone,
    this.brokerAddress,
    this.notes,
    required this.items,
    required this.totals,
    required this.photoPaths,
  });

  /// Calculate total number of pages needed for this voucher
  /// Assuming ~15 items per page with header/footer
  int get estimatedPages {
    if (items.isEmpty) return 1;
    return ((items.length - 1) ~/ 15) + 1;
  }

  /// Check if this voucher has any photos
  bool get hasPhotos => photoPaths.isNotEmpty;

  /// Get formatted date string (Myanmar format)
  String get formattedDate {
    final date = DateTime.fromMillisecondsSinceEpoch(voucherDate);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class BrokerVoucherDocumentItem {
  final int itemNumber; // 1-based index
  final String itemName;
  final String sourceType; // 'အပြည့်အစုံ' or 'အခွဲ'
  /// Nullable: null means no consignment-specific weight was entered.
  /// Display '-' when null. Never fall back to gemstone inventory weight.
  final double? weight;
  final String? weightUnit; // 'ကျပ်' or 'ဂရမ်' — null when weight is null
  final double consignedQuantity;
  final double soldQuantity;
  final double returnedQuantity;
  final double remainingQuantity;
  final String? notes;
  final List<String> photoPaths;

  BrokerVoucherDocumentItem({
    required this.itemNumber,
    required this.itemName,
    required this.sourceType,
    this.weight,
    this.weightUnit,
    required this.consignedQuantity,
    required this.soldQuantity,
    required this.returnedQuantity,
    required this.remainingQuantity,
    this.notes,
    required this.photoPaths,
  });

  /// Formatted weight string: '-' when no weight, otherwise 'value unit'
  String get weightDisplay {
    if (weight == null || weight == 0) return '-';
    final unit = weightUnit ?? '';
    return unit.isNotEmpty ? '$weight $unit' : '$weight';
  }

  /// Check if this item has any photos
  bool get hasPhotos => photoPaths.isNotEmpty;
}

class BrokerVoucherDocumentTotals {
  final int distinctItemCount;
  final double totalConsignedQuantity;
  final double totalSoldQuantity;
  final double totalReturnedQuantity;
  final double totalRemainingQuantity;

  BrokerVoucherDocumentTotals({
    required this.distinctItemCount,
    required this.totalConsignedQuantity,
    required this.totalSoldQuantity,
    required this.totalReturnedQuantity,
    required this.totalRemainingQuantity,
  });

  /// Check if voucher is fully completed (no remaining items)
  bool get isCompleted => totalRemainingQuantity <= 0;
}
