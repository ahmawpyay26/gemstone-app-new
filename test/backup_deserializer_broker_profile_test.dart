import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone_management/features/settings/data/backup_deserializers.dart';

void main() {
  group('BrokerProfile Deserialization Tests', () {
    test('Deserialize valid broker profile with all fields', () {
      final json = {
        'id': 'bp_001',
        'name': 'Aung Aung',
        'nationalId': '12345678',
        'phone': '09123456789',
        'address': 'Yangon, Myanmar',
        'socialAccount': '@aungaung',
        'note': 'Reliable broker',
        'profileImagePath': '/images/profile.jpg',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
        'isDeleted': false,
        'deletedAt': null,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);

      expect(result, isNotNull);
      expect(result!.id, 'bp_001');
      expect(result.name, 'Aung Aung');
      expect(result.nationalId, '12345678');
      expect(result.phone, '09123456789');
      expect(result.address, 'Yangon, Myanmar');
      expect(result.socialAccount, '@aungaung');
      expect(result.note, 'Reliable broker');
      expect(result.profileImagePath, '/images/profile.jpg');
      expect(result.createdAt, 1704067200000);
      expect(result.updatedAt, 1704067200000);
      expect(result.isDeleted, false);
      expect(result.deletedAt, null);
    });

    test('Deserialize broker profile with minimal required fields', () {
      final json = {
        'id': 'bp_002',
        'name': 'Ko Ko',
        'phone': '09987654321',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);

      expect(result, isNotNull);
      expect(result!.id, 'bp_002');
      expect(result.name, 'Ko Ko');
      expect(result.phone, '09987654321');
      expect(result.nationalId, null);
      expect(result.address, null);
      expect(result.socialAccount, null);
      expect(result.note, null);
      expect(result.profileImagePath, null);
    });

    test('Deserialize broker profile with optional fields as empty strings', () {
      final json = {
        'id': 'bp_003',
        'name': 'Ma Ma',
        'phone': '09111111111',
        'nationalId': '',
        'address': '',
        'socialAccount': '',
        'note': '',
        'profileImagePath': '',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
        'isDeleted': false,
        'deletedAt': null,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);

      expect(result, isNotNull);
      expect(result!.id, 'bp_003');
      expect(result.nationalId, '');
      expect(result.address, '');
      expect(result.socialAccount, '');
      expect(result.note, '');
      expect(result.profileImagePath, '');
    });

    test('Fail deserialization when id is missing', () {
      final json = {
        'name': 'Test Broker',
        'phone': '09123456789',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when id is empty string', () {
      final json = {
        'id': '',
        'name': 'Test Broker',
        'phone': '09123456789',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when name is missing', () {
      final json = {
        'id': 'bp_004',
        'phone': '09123456789',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when name is empty string', () {
      final json = {
        'id': 'bp_005',
        'name': '',
        'phone': '09123456789',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when phone is missing', () {
      final json = {
        'id': 'bp_006',
        'name': 'Test Broker',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when phone is empty string', () {
      final json = {
        'id': 'bp_007',
        'name': 'Test Broker',
        'phone': '',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when createdAt is missing', () {
      final json = {
        'id': 'bp_008',
        'name': 'Test Broker',
        'phone': '09123456789',
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when createdAt is negative', () {
      final json = {
        'id': 'bp_009',
        'name': 'Test Broker',
        'phone': '09123456789',
        'createdAt': -1,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when updatedAt is missing', () {
      final json = {
        'id': 'bp_010',
        'name': 'Test Broker',
        'phone': '09123456789',
        'createdAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Fail deserialization when updatedAt is negative', () {
      final json = {
        'id': 'bp_011',
        'name': 'Test Broker',
        'phone': '09123456789',
        'createdAt': 1704067200000,
        'updatedAt': -1,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });

    test('Deserialize broker profile with isDeleted true and deletedAt timestamp', () {
      final json = {
        'id': 'bp_012',
        'name': 'Deleted Broker',
        'phone': '09999999999',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
        'isDeleted': true,
        'deletedAt': 1704153600000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);

      expect(result, isNotNull);
      expect(result!.isDeleted, true);
      expect(result.deletedAt, 1704153600000);
    });

    test('Deserialize broker profile with isDeleted false defaults correctly', () {
      final json = {
        'id': 'bp_013',
        'name': 'Active Broker',
        'phone': '09111111111',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);

      expect(result, isNotNull);
      expect(result!.isDeleted, false);
      expect(result.deletedAt, null);
    });

    test('Deserialize broker profile with type mismatches throws gracefully', () {
      final json = {
        'id': 123, // Should be String
        'name': 'Test Broker',
        'phone': '09123456789',
        'createdAt': 1704067200000,
        'updatedAt': 1704067200000,
      };

      final result = BackupDeserializers.deserializeBrokerProfile(json);
      expect(result, isNull);
    });
  });
}
