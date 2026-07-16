import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'dart:developer' as developer;

/// Represents a draft item in the Broker Consignment form
class DraftConsignmentItem {
  final String id;
  final Gemstone? gemstone;
  final double consignedQuantity;
  final String sourceType; // 'whole_stone' or 'breakdown_item'
  final Gemstone? selectedPurchase; // For breakdown_item source type
  final String? selectedBreakdownItem; // Selected breakdown item name
  final Map<String, int> availableBreakdownItems; // Filtered breakdown items from purchase

  DraftConsignmentItem({
    required this.id,
    this.gemstone,
    this.consignedQuantity = 0,
    this.sourceType = 'whole_stone',
    this.selectedPurchase,
    this.selectedBreakdownItem,
    this.availableBreakdownItems = const {},
  });

  /// Get unique source identity for grouping
  /// Whole: purchaseRecordId + sourceType
  /// Fragment: breakdownItemId + sourceType
  String get sourceIdentity {
    if (sourceType == 'breakdown_item') {
      return '${selectedPurchase?.id}_${selectedBreakdownItem}_$sourceType';
    } else {
      return '${gemstone?.id}_$sourceType';
    }
  }
}

/// Validation result with error message
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({required this.isValid, this.errorMessage});

  factory ValidationResult.success() => ValidationResult(isValid: true);
  factory ValidationResult.error(String message) =>
      ValidationResult(isValid: false, errorMessage: message);
}

/// Business logic for Broker Consignment Draft Validation
class BrokerConsignmentValidation {
  /// Calculate total draft quantity for a specific source identity
  static double _calculateDraftQuantityForSource(
    List<DraftConsignmentItem> draftItems,
    String sourceIdentity,
  ) {
    return draftItems
        .where((item) => item.sourceIdentity == sourceIdentity)
        .fold<double>(0, (sum, item) => sum + item.consignedQuantity);
  }

  /// Calculate available quantity for a new/edited item considering draft items
  /// Formula: Available = Database Remaining - Draft Quantity (same source)
  static double calculateDraftAwareAvailableQuantity({
    required DraftConsignmentItem newItem,
    required List<DraftConsignmentItem> existingDraftItems,
    required String? editingItemId, // null for new item, set for editing
  }) {
    try {
      // Get database remaining quantity
      double databaseRemaining;
      String sourceType = newItem.sourceType;
      String sourceIdentity = newItem.sourceIdentity;

      developer.log(
        '[VALIDATION] calculateDraftAwareAvailableQuantity START',
        name: 'BrokerConsignmentValidation',
      );
      developer.log(
        'Source Type: $sourceType | Source Identity: $sourceIdentity',
        name: 'BrokerConsignmentValidation',
      );

      if (newItem.sourceType == 'breakdown_item') {
        // For fragment: get fragment remaining
        if (newItem.selectedPurchase == null || newItem.selectedBreakdownItem == null) {
          developer.log(
            'ERROR: Fragment source but selectedPurchase or selectedBreakdownItem is null',
            name: 'BrokerConsignmentValidation',
            level: 1000,
          );
          return 0;
        }
        final breakdownItem = newItem.selectedPurchase!.breakdownItems[newItem.selectedBreakdownItem];
        if (breakdownItem == null) {
          developer.log(
            'ERROR: Breakdown item not found: ${newItem.selectedBreakdownItem}',
            name: 'BrokerConsignmentValidation',
            level: 1000,
          );
          return 0;
        }

        final itemData = breakdownItem as Map<String, dynamic>?;
        databaseRemaining = (itemData?['quantity'] as num?)?.toDouble() ?? 0;
        developer.log(
          'Fragment Source | PurchaseId: ${newItem.selectedPurchase!.id} | BreakdownItem: ${newItem.selectedBreakdownItem} | DatabaseRemaining: $databaseRemaining',
          name: 'BrokerConsignmentValidation',
        );
      } else {
        // For whole stone: get whole remaining
        if (newItem.gemstone == null) {
          developer.log(
            'ERROR: Whole stone source but gemstone is null',
            name: 'BrokerConsignmentValidation',
            level: 1000,
          );
          return 0;
        }
        databaseRemaining = LocalDb.gemstoneRemainingQuantity(newItem.gemstone!).toDouble();
        developer.log(
          'Whole Stone Source | GemstoneId: ${newItem.gemstone!.id} | GemName: ${newItem.gemstone!.name} | DatabaseRemaining: $databaseRemaining',
          name: 'BrokerConsignmentValidation',
        );
      }

      // Calculate total draft quantity for this source (excluding the item being edited)
      double draftQuantity = 0;
      int matchingDraftItems = 0;
      for (final item in existingDraftItems) {
        // Skip the item being edited (if any)
        if (editingItemId != null && item.id == editingItemId) {
          developer.log(
            'Skipping editing item: ${item.id}',
            name: 'BrokerConsignmentValidation',
          );
          continue;
        }
        // Only count items with the same source identity
        if (item.sourceIdentity == sourceIdentity) {
          draftQuantity += item.consignedQuantity;
          matchingDraftItems++;
          developer.log(
            'Counting draft item: ${item.id} | Quantity: ${item.consignedQuantity} | SourceIdentity: ${item.sourceIdentity}',
            name: 'BrokerConsignmentValidation',
          );
        }
      }

      developer.log(
        'Draft Summary | MatchingItems: $matchingDraftItems | TotalDraftQuantity: $draftQuantity',
        name: 'BrokerConsignmentValidation',
      );

      // Calculate available: Database Remaining - Draft Quantity
      final available = databaseRemaining - draftQuantity;
      developer.log(
        'Available Calculation | DatabaseRemaining: $databaseRemaining - DraftQuantity: $draftQuantity = Available: $available',
        name: 'BrokerConsignmentValidation',
      );

      return available > 0 ? available : 0;
    } catch (e, stackTrace) {
      developer.log(
        'EXCEPTION in calculateDraftAwareAvailableQuantity: $e',
        name: 'BrokerConsignmentValidation',
        level: 1000,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Validate a new/edited item against draft-aware available quantity
  static ValidationResult validateItemQuantity({
    required DraftConsignmentItem item,
    required List<DraftConsignmentItem> existingDraftItems,
    required String? editingItemId, // null for new item, set for editing
  }) {
    try {
      developer.log(
        '[VALIDATION] validateItemQuantity START | ItemId: ${item.id} | Quantity: ${item.consignedQuantity} | SourceType: ${item.sourceType}',
        name: 'BrokerConsignmentValidation',
      );

      // Validate quantity is positive
      if (item.consignedQuantity <= 0) {
        developer.log(
          'VALIDATION FAILED: Quantity <= 0',
          name: 'BrokerConsignmentValidation',
          level: 1000,
        );
        return ValidationResult.error('အရေအတွက်သည် 0 ထက် ကြီးရမည်။');
      }

      // Branch validation by source type
      if (item.sourceType == 'breakdown_item') {
        // For fragment: validate against fragment remaining
        if (item.selectedPurchase == null || item.selectedBreakdownItem == null) {
          developer.log(
            'VALIDATION FAILED: Fragment source but selectedPurchase or selectedBreakdownItem is null',
            name: 'BrokerConsignmentValidation',
            level: 1000,
          );
          return ValidationResult.error('ကျောက်အစိတ်စိတ်ပိုင်းကို ရွေးချယ်ပါ။');
        }

        // Calculate available quantity for this fragment
        final available = calculateDraftAwareAvailableQuantity(
          newItem: item,
          existingDraftItems: existingDraftItems,
          editingItemId: editingItemId,
        );

        developer.log(
          'Fragment Validation | RequestedQuantity: ${item.consignedQuantity} | AvailableQuantity: $available',
          name: 'BrokerConsignmentValidation',
        );

        if (item.consignedQuantity > available) {
          developer.log(
            'VALIDATION FAILED: Requested > Available',
            name: 'BrokerConsignmentValidation',
            level: 1000,
          );
          return ValidationResult.error(
            'ထည့်သွင်းသောအရေအတွက်သည် ကျန်ရှိအရေအတွက် $available ထက် မများရပါ။',
          );
        }
      } else {
        // For whole stone: validate against whole remaining
        if (item.gemstone == null) {
          developer.log(
            'VALIDATION FAILED: Whole stone source but gemstone is null',
            name: 'BrokerConsignmentValidation',
            level: 1000,
          );
          return ValidationResult.error('ကျောက်မျက်ကို ရွေးချယ်ပါ။');
        }

        // Calculate available quantity for this whole stone
        final available = calculateDraftAwareAvailableQuantity(
          newItem: item,
          existingDraftItems: existingDraftItems,
          editingItemId: editingItemId,
        );

        developer.log(
          'Whole Stone Validation | RequestedQuantity: ${item.consignedQuantity} | AvailableQuantity: $available',
          name: 'BrokerConsignmentValidation',
        );

        if (item.consignedQuantity > available) {
          developer.log(
            'VALIDATION FAILED: Requested > Available',
            name: 'BrokerConsignmentValidation',
            level: 1000,
          );
          return ValidationResult.error(
            'ထည့်သွင်းသောအရေအတွက်သည် ကျန်ရှိအရေအတွက် $available ထက် မများရပါ။',
          );
        }
      }

      developer.log(
        'VALIDATION PASSED',
        name: 'BrokerConsignmentValidation',
      );
      return ValidationResult.success();
    } catch (e, stackTrace) {
      developer.log(
        'EXCEPTION in validateItemQuantity: $e',
        name: 'BrokerConsignmentValidation',
        level: 1000,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Validate entire form before final save
  /// Re-validates against current database state (not draft state)
  static ValidationResult validateFormBeforeSave({
    required List<DraftConsignmentItem> allItems,
  }) {
    if (allItems.isEmpty) {
      return ValidationResult.error('အနည်းဆုံး အရာ ၁ ခုထည့်သွင်းပါ။');
    }

    // Group items by source identity to validate each group independently
    final groupedBySource = <String, List<DraftConsignmentItem>>{};
    for (final item in allItems) {
      final identity = item.sourceIdentity;
      groupedBySource.putIfAbsent(identity, () => []).add(item);
    }

    // Validate each source group against current database remaining
    for (final identity in groupedBySource.keys) {
      final items = groupedBySource[identity]!;
      final totalQuantity = items.fold<double>(0, (sum, item) => sum + item.consignedQuantity);

      // Get current database remaining for this source
      double databaseRemaining;
      final firstItem = items.first;

      if (firstItem.sourceType == 'breakdown_item') {
        // For fragment: get fragment remaining
        if (firstItem.selectedPurchase == null || firstItem.selectedBreakdownItem == null) {
          return ValidationResult.error('ကျောက်အစိတ်စိတ်ပိုင်းအချက်အလက် မပြည့်စုံပါ။');
        }
        final breakdownItem = firstItem.selectedPurchase!.breakdownItems[firstItem.selectedBreakdownItem];
        if (breakdownItem == null) {
          return ValidationResult.error('ကျောက်အစိတ်စိတ်ပိုင်းမတွေ့ရှိပါ။');
        }
        final itemData = breakdownItem as Map<String, dynamic>?;
        databaseRemaining = (itemData?['quantity'] as num?)?.toDouble() ?? 0;
      } else {
        // For whole stone: get whole remaining
        if (firstItem.gemstone == null) {
          return ValidationResult.error('ကျောက်မျက်အချက်အလက် မပြည့်စုံပါ။');
        }
        databaseRemaining = LocalDb.gemstoneRemainingQuantity(firstItem.gemstone!).toDouble();
      }

      // Check if total quantity exceeds current database remaining
      if (totalQuantity > databaseRemaining) {
        return ValidationResult.error(
          '${firstItem.gemstoneName} အတွက် စုစုပေါင်း $totalQuantity ခုထည့်သွင်းလိုသည်သော်လည်း ကျန်ရှိအရေအတွက် $databaseRemaining သာ ရှိသည်။',
        );
      }
    }

    return ValidationResult.success();
  }

  /// Get gemstone name for display
  static String getGemstoneName(DraftConsignmentItem item) {
    if (item.sourceType == 'breakdown_item') {
      return item.selectedPurchase?.name ?? 'Unknown';
    } else {
      return item.gemstone?.name ?? 'Unknown';
    }
  }
}

extension on DraftConsignmentItem {
  String get gemstoneName => BrokerConsignmentValidation.getGemstoneName(this);
}
