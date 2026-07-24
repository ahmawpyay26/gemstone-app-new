// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_license_identity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveLicenseIdentityAdapter extends TypeAdapter<HiveLicenseIdentity> {
  @override
  final int typeId = 18;

  @override
  HiveLicenseIdentity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveLicenseIdentity(
      installationId: fields[0] as String,
      firstInstallTime: fields[1] as int,
      lastOpenedTime: fields[2] as int,
      currentVersion: fields[3] as String,
      buildNumber: fields[4] as int,
      licenseStatus: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveLicenseIdentity obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.installationId)
      ..writeByte(1)
      ..write(obj.firstInstallTime)
      ..writeByte(2)
      ..write(obj.lastOpenedTime)
      ..writeByte(3)
      ..write(obj.currentVersion)
      ..writeByte(4)
      ..write(obj.buildNumber)
      ..writeByte(5)
      ..write(obj.licenseStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveLicenseIdentityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
