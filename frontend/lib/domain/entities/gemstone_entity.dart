import 'package:equatable/equatable.dart';

class GemstoneEntity extends Equatable {
  final String id;
  final String qrCode;
  final String type;
  final double caratWeight;
  final String status;
  final double totalCost;
  final String? lotId;

  const GemstoneEntity({
    required this.id,
    required this.qrCode,
    required this.type,
    required this.caratWeight,
    required this.status,
    required this.totalCost,
    this.lotId,
  });

  @override
  List<Object?> get props => [id, qrCode, type, caratWeight, status, totalCost, lotId];
}
