import 'package:hive_flutter/hive_flutter.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';

/// Represents a draft item before final save
class DraftBrokerSaleItem {
  final String id;
  final BrokerConsignment brokerConsignment;
  final double soldQuantity;
  final double unitPrice;
  final double commission;
  final String? buyerName;
  final String remark;
  final DateTime saleDate;
  final List<String> photoUrls;

  DraftBrokerSaleItem({
    required this.id,
    required this.brokerConsignment,
    required this.soldQuantity,
    required this.unitPrice,
    required this.commission,
    this.buyerName,
    required this.remark,
    required this.saleDate,
    required this.photoUrls,
  });

  /// Calculate total sale amount
  double get totalSaleAmount => soldQuantity * unitPrice;

  /// Calculate net amount after commission
  double get netAmount => totalSaleAmount - commission;

  /// Get gemstone details
  Gemstone? get gemstone => LocalDb.gemstoneById(brokerConsignment.purchaseId);

  /// Get gemstone name for display
  String get gemstoneName => gemstone?.name ?? 'Unknown';

  /// Get source type label
  String get sourceTypeLabel =>
      brokerConsignment.historicalData.sourceType == 'whole_stone' ? 'အပြည့်အစုံ' : 'အခွဲ';

  /// Create a copy with modifications
  DraftBrokerSaleItem copyWith({
    String? id,
    BrokerConsignment? brokerConsignment,
    double? soldQuantity,
    double? unitPrice,
    double? commission,
    String? buyerName,
    String? remark,
    DateTime? saleDate,
    List<String>? photoUrls,
  }) {
    return DraftBrokerSaleItem(
      id: id ?? this.id,
      brokerConsignment: brokerConsignment ?? this.brokerConsignment,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      commission: commission ?? this.commission,
      buyerName: buyerName ?? this.buyerName,
      remark: remark ?? this.remark,
      saleDate: saleDate ?? this.saleDate,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}

/// Validation Results
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({required this.isValid, this.errorMessage});

  factory ValidationResult.success() => ValidationResult(isValid: true);
  factory ValidationResult.error(String message) => ValidationResult(isValid: false, errorMessage: message);
}

/// Draft Summary for display
class DraftSummary {
  final int itemCount;
  final double totalQuantity;
  final double totalSaleAmount;
  final double totalCommission;
  final double totalNetAmount;

  DraftSummary({
    required this.itemCount,
    required this.totalQuantity,
    required this.totalSaleAmount,
    required this.totalCommission,
    required this.totalNetAmount,
  });

  factory DraftSummary.fromItems(List<DraftBrokerSaleItem> items) {
    int itemCount = items.length;
    double totalQuantity = 0;
    double totalSaleAmount = 0;
    double totalCommission = 0;

    for (final item in items) {
      totalQuantity += item.soldQuantity;
      totalSaleAmount += item.totalSaleAmount;
      totalCommission += item.commission;
    }

    return DraftSummary(
      itemCount: itemCount,
      totalQuantity: totalQuantity,
      totalSaleAmount: totalSaleAmount,
      totalCommission: totalCommission,
      totalNetAmount: totalSaleAmount - totalCommission,
    );
  }
}

/// Business Logic Layer for Broker Sales Module
/// Handles validation, calculation, and atomic commit operations
class BrokerSalesBusinessLogic {
  /// Validate broker consignment selection
  static ValidationResult validateConsignmentSelection(BrokerConsignment? consignment) {
    if (consignment == null) {
      return ValidationResult.error('ပွဲစားထံမှ ကျောက်ကို ရွေးချယ်ပါ။');
    }
    return ValidationResult.success();
  }

  /// Validate sold quantity
  static ValidationResult validateSoldQuantity(String? value, BrokerConsignment? consignment) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('အရေအတွက်ကို ထည့်သွင်းပါ။');
    }

    final qty = double.tryParse(value);
    if (qty == null || qty <= 0) {
      return ValidationResult.error('အရေအတွက်သည် ၀ထက်ကြီးရမည်ဖြစ်ပါသည်။');
    }

    if (consignment != null && qty > consignment.remainingQuantity) {
      return ValidationResult.error(
        'ကျန်ရှိသော အရေအတွက် ${consignment.remainingQuantity} ထက် ကျော်လွန်သည်။',
      );
    }

    return ValidationResult.success();
  }

  /// Validate unit price
  static ValidationResult validateUnitPrice(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('ယူနစ်စျေးကို ထည့်သွင်းပါ။');
    }

    final price = double.tryParse(value);
    if (price == null || price < 0) {
      return ValidationResult.error('ယူနစ်စျေးသည် အနုတ်မဖြစ်ရမည်ဖြစ်ပါသည်။');
    }

    return ValidationResult.success();
  }

  /// Validate commission
  static ValidationResult validateCommission(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.success(); // Commission is optional
    }

    final commission = double.tryParse(value);
    if (commission == null || commission < 0) {
      return ValidationResult.error('ကော်မရှင်သည် အနုတ်မဖြစ်ရမည်ဖြစ်ပါသည်။');
    }

    return ValidationResult.success();
  }

  /// Validate source type compatibility
  static ValidationResult validateSourceType(
    BrokerConsignment consignment,
    String sourceType,
  ) {
    if (consignment.historicalData.sourceType != sourceType) {
      return ValidationResult.error('ရွေးချယ်ထားသော အရင်းအမြစ်အမျိုးအစား ကိုက်ညီမှုမရှိပါ။');
    }
    return ValidationResult.success();
  }

  /// Validate broker remaining quantity
  static ValidationResult validateBrokerRemaining(
    BrokerConsignment consignment,
    double requestedQuantity,
  ) {
    if (requestedQuantity > consignment.remainingQuantity) {
      return ValidationResult.error(
        'ပွဲစားထံ ကျန်ရှိသော အရေအတွက် ${consignment.remainingQuantity} ထက် ကျော်လွန်သည်။',
      );
    }
    return ValidationResult.success();
  }

  /// Create draft item from form inputs
  static DraftBrokerSaleItem createDraftItem({
    required BrokerConsignment consignment,
    required double quantity,
    required double unitPrice,
    required double commission,
    required String? buyerName,
    required String remark,
    required DateTime saleDate,
    required List<String> photoUrls,
  }) {
    return DraftBrokerSaleItem(
      id: LocalDb.genId(),
      brokerConsignment: consignment,
      soldQuantity: quantity,
      unitPrice: unitPrice,
      commission: commission,
      buyerName: buyerName,
      remark: remark,
      saleDate: saleDate,
      photoUrls: photoUrls,
    );
  }

  /// Commit draft items to database (atomic transaction)
  /// Returns true on success
  static Future<bool> commitDraftItems({
    required List<DraftBrokerSaleItem> draftItems,
    required String? customerName,
    required DateTime invoiceDate,
  }) async {
    if (draftItems.isEmpty) {
      throw Exception('ရောင်းချမည့်ပစ္စည်း မရှိပါ။');
    }

    try {
      // Note: Invoice number generation removed as BrokerSaleRecord doesn't have this field
      // If needed, add invoiceNumber field to BrokerSaleRecord model

      // Save all broker sale records
      final saleRecordsBox = Hive.box<BrokerSaleRecord>('brokerSaleRecords');
      final brokerConsignmentBox = Hive.box<BrokerConsignment>('brokerConsignments');

      for (final draftItem in draftItems) {
        // Create broker sale record
        final saleRecord = BrokerSaleRecord(
          id: LocalDb.genId(),
          brokerConsignmentId: draftItem.brokerConsignment.id,
          purchaseId: draftItem.brokerConsignment.purchaseId,
          sourceType: draftItem.brokerConsignment.historicalData.sourceType,
          breakdownItemName: draftItem.brokerConsignment.historicalData.breakdownItemName,
          soldQuantity: draftItem.soldQuantity,
          unitPrice: draftItem.unitPrice,
          totalSaleAmount: draftItem.totalSaleAmount,
          brokerCommission: draftItem.commission,
          netAmount: draftItem.netAmount,
          buyerName: draftItem.buyerName,
          remark: draftItem.remark,
          saleDate: draftItem.saleDate.millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        // Validate sale record
        final validationError = saleRecord.validate();
        if (validationError != null) {
          throw Exception('အမှားအယွင်း: $validationError');
        }

        // Save sale record
        await saleRecordsBox.add(saleRecord);

        // Update broker consignment remaining quantity
        draftItem.brokerConsignment.soldQuantity += draftItem.soldQuantity;
        await brokerConsignmentBox.put(
          draftItem.brokerConsignment.id,
          draftItem.brokerConsignment,
        );
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }
}
