// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'license_activation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveLicenseActivationAdapter extends TypeAdapter<HiveLicenseActivation> {
  @override
  final int typeId = 19;

  @override
  HiveLicenseActivation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveLicenseActivation(
      activationKey: fields[0] as String,
      installationId: fields[1] as String,
      activatedAt: fields[2] as int,
      activationStatus: fields[3] as String,
      appVersion: fields[4] as String,
      schemaVersion: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveLicenseActivation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.activationKey)
      ..writeByte(1)
      ..write(obj.installationId)
      ..writeByte(2)
      ..write(obj.activatedAt)
      ..writeByte(3)
      ..write(obj.activationStatus)
      ..writeByte(4)
      ..write(obj.appVersion)
      ..writeByte(5)
      ..write(obj.schemaVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveLicenseActivationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
