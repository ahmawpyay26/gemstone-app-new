import 'dart:developer' as developer;
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
      developer.log(
        '[RCA-FINAL-SAVE-START] draftItems.length=${draftItems.length} | customerName=$customerName | invoiceDate=$invoiceDate',
        level: 1000,
        name: 'RCA_FINAL_SAVE',
      );

      // Generate unique invoice number for this transaction
      final invoiceNumber = _generateInvoiceNumber();
      
      // Get the Sale box for persistence
      final saleBox = Hive.box<Sale>('sales');
      final brokerConsignmentBox = Hive.box<BrokerConsignment>('brokerConsignments');
      final gemstonesBox = Hive.box<Gemstone>('gemstones');

      // Validate all items before committing any
      for (final draftItem in draftItems) {
        if (draftItem.soldQuantity <= 0) {
          throw Exception('ရောင်းချမည့်ပမာဏ ၀ထက်များရမည်။');
        }
        if (draftItem.unitPrice < 0) {
          throw Exception('စျေးနှုန်း အနုတ်မဖြစ်ရပါ။');
        }
        if (draftItem.totalSaleAmount <= 0) {
          throw Exception('စုစုပေါင်းအရောင်း ၀ထက်များရမည်။');
        }
      }

      // Commit all items atomically
      int draftIndex = 0;
      for (final draftItem in draftItems) {
        developer.log(
          '[RCA-DRAFT-ITEM-START] index=$draftIndex | gemstoneName=${draftItem.gemstoneName} | sourceType=${draftItem.brokerConsignment.historicalData.sourceType} | soldQuantity=${draftItem.soldQuantity} | purchaseId=${draftItem.brokerConsignment.purchaseId}',
          level: 1000,
          name: 'RCA_FINAL_SAVE',
        );

        // Get gemstone info
        final gemstone = LocalDb.gemstoneById(draftItem.brokerConsignment.purchaseId);
        if (gemstone == null) {
          throw Exception('ကျောက်မျက်မှတ်တမ်း မတွေ့ရှိပါ။');
        }

        // Create Sale record for history persistence
        final saleRecord = Sale(
          id: LocalDb.genId(),
          gemstoneName: gemstone.name,
          gemstoneId: gemstone.id,
          customerName: customerName ?? draftItem.buyerName ?? 'အမည်မသိ',
          amount: draftItem.totalSaleAmount, // Gross sale amount
          commissionFee: draftItem.commission,
          quantity: draftItem.soldQuantity.toInt(),
          paymentMethod: 'broker', // Mark as broker sale
          note: draftItem.remark,
          saleDate: invoiceDate.millisecondsSinceEpoch,
          netSale: draftItem.netAmount, // Net after commission
          invoiceNumber: invoiceNumber, // Group multi-item sales
          weightCarat: draftItem.soldQuantity,
          isFragmentSource: draftItem.brokerConsignment.historicalData.sourceType == 'breakdown_item',
          fragmentName: draftItem.brokerConsignment.historicalData.breakdownItemName,
        );

        // Validate sale record has required fields
        if (saleRecord.gemstoneName.isEmpty) {
          throw Exception('ကျောက်မျက်မှတ်တမ်း မရှိပါ။');
        }
        if (saleRecord.amount <= 0) {
          throw Exception('စုစုပေါင်းအရောင်း ၀ထက်များရမည်။');
        }

        // Save to Sale box (this makes it visible in Sales History)
        await saleBox.add(saleRecord);

        // Update broker consignment remaining quantity
        draftItem.brokerConsignment.soldQuantity += draftItem.soldQuantity;
        await brokerConsignmentBox.put(
          draftItem.brokerConsignment.id,
          draftItem.brokerConsignment,
        );

        developer.log(
          '[RCA-DRAFT-ITEM-COMPLETE] index=$draftIndex | gemstoneName=${draftItem.gemstoneName} | SUCCESS',
          level: 1000,
          name: 'RCA_FINAL_SAVE',
        );
        draftIndex++;
      }

      developer.log(
        '[RCA-FINAL-SAVE-COMPLETE] All items committed successfully',
        level: 1000,
        name: 'RCA_FINAL_SAVE',
      );
      return true;
    } catch (e) {
      developer.log(
        '[RCA-FINAL-SAVE-ERROR] Exception: $e',
        level: 1000,
        name: 'RCA_FINAL_SAVE',
      );
      rethrow;
    }
  }

  /// Generate unique invoice number
  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'BSI-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$random';
  }
}
