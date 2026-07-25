/// Backup deserializers for Phase 2+ restore.
/// Converts JSON backup data back to model instances.

import 'package:gemstone_management/core/local/models.dart';

class BackupDeserializers {
  /// Deserialize Gemstone from backup JSON record
  /// Returns null if deserialization fails (invalid data)
  static Gemstone? deserializeGemstone(Map<String, dynamic> json) {
    try {
      // Required fields
      final id = json['id'] as String?;
      final name = json['name'] as String?;
      final type = json['type'] as String?;
      final weightCarat = (json['weightCarat'] as num?)?.toDouble();
      final costPrice = (json['costPrice'] as num?)?.toDouble();
      final quantity = json['quantity'] as int?;
      final color = json['color'] as String?;
      final origin = json['origin'] as String?;
      final status = json['status'] as String?;
      final note = json['note'] as String?;
      final createdAt = json['createdAt'] as int?;

      // Validate required fields
      if (id == null ||
          name == null ||
          type == null ||
          weightCarat == null ||
          costPrice == null ||
          quantity == null ||
          color == null ||
          origin == null ||
          status == null ||
          note == null ||
          createdAt == null) {
        return null;
      }

      // Optional fields with defaults
      final weightUnit = (json['weightUnit'] as String?) ?? 'carat';
      final commissionFee = (json['commissionFee'] as num?)?.toDouble() ?? 0;
      final processingFee = (json['processingFee'] as num?)?.toDouble() ?? 0;
      final repairFee = (json['repairFee'] as num?)?.toDouble() ?? 0;
      final breakageFee = (json['breakageFee'] as num?)?.toDouble() ?? 0;
      final bloodFee = (json['bloodFee'] as num?)?.toDouble() ?? 0;
      final laborFee = (json['laborFee'] as num?)?.toDouble() ?? 0;
      final miscFee = (json['miscFee'] as num?)?.toDouble() ?? 0;
      final sellPrice = (json['sellPrice'] as num?)?.toDouble() ?? 0;
      final totalCost = (json['totalCost'] as num?)?.toDouble() ?? 0;
      final remainingCost = (json['remainingCost'] as num?)?.toDouble() ?? 0;
      final remainingQuantity = (json['remainingQuantity'] as int?) ?? 0;
      final soldQuantity = (json['soldQuantity'] as int?) ?? 0;
      final photoPaths = (json['photoPaths'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [];
      final originalPurchaseCost =
          (json['originalPurchaseCost'] as num?)?.toDouble() ?? 0;
      final remainingCostBalance =
          (json['remainingCostBalance'] as num?)?.toDouble() ?? 0;
      final recoveredCost = (json['recoveredCost'] as num?)?.toDouble() ?? 0;
      final totalProfit = (json['totalProfit'] as num?)?.toDouble();
      final totalSalesRevenue =
          (json['totalSalesRevenue'] as num?)?.toDouble();

      // Deserialize breakdownItems
      final breakdownItemsJson = json['breakdownItems'] as Map<String, dynamic>?;
      final breakdownItems = <String, Map<String, dynamic>>{};
      if (breakdownItemsJson != null) {
        breakdownItemsJson.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            breakdownItems[key] = Map<String, dynamic>.from(value);
          }
        });
      }

      return Gemstone(
        id: id,
        name: name,
        type: type,
        weightCarat: weightCarat,
        weightUnit: weightUnit,
        costPrice: costPrice,
        commissionFee: commissionFee,
        processingFee: processingFee,
        repairFee: repairFee,
        breakageFee: breakageFee,
        bloodFee: bloodFee,
        laborFee: laborFee,
        miscFee: miscFee,
        sellPrice: sellPrice,
        quantity: quantity,
        color: color,
        origin: origin,
        status: status,
        note: note,
        createdAt: createdAt,
        totalCost: totalCost,
        remainingCost: remainingCost,
        remainingQuantity: remainingQuantity,
        soldQuantity: soldQuantity,
        photoPaths: photoPaths,
        breakdownItems: breakdownItems,
        originalPurchaseCost: originalPurchaseCost,
        remainingCostBalance: remainingCostBalance,
        recoveredCost: recoveredCost,
        totalProfit: totalProfit,
        totalSalesRevenue: totalSalesRevenue,
      );
    } catch (e) {
      return null;
    }
  }
}
