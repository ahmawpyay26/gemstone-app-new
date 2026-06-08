import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/gemstone_entity.dart';
import '../datasources/local/app_database.dart';

part 'gemstone_model.g.dart';

@JsonSerializable()
class GemstoneModel extends GemstoneEntity {
  const GemstoneModel({
    required String id,
    required String qrCode,
    required String type,
    required double caratWeight,
    required String status,
    required double totalCost,
    String? lotId,
  }) : super(
          id: id,
          qrCode: qrCode,
          type: type,
          caratWeight: caratWeight,
          status: status,
          totalCost: totalCost,
          lotId: lotId,
        );

  factory GemstoneModel.fromJson(Map<String, dynamic> json) => _$GemstoneModelFromJson(json);
  Map<String, dynamic> toJson() => _$GemstoneModelToJson(this);

  // Conversion to Local Model (Drift)
  LocalGemstone toLocalModel({bool isSynced = false}) {
    return LocalGemstone(
      id: id,
      qrCode: qrCode,
      type: type,
      caratWeight: caratWeight,
      status: status,
      totalCost: totalCost,
      lotId: lotId,
      isSynced: isSynced,
      lastUpdated: DateTime.now(),
    );
  }
}
