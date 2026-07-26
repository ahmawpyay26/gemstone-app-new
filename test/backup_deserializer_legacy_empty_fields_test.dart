import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone_management/features/settings/data/backup_deserializers.dart';

void main() {
  group('Legacy Empty Field Compatibility Tests', () {
    // Test 1: Empty purchaseId should deserialize successfully
    test('Deserialize BrokerConsignment with empty purchaseId', () {
      final json = {
        'id': 'bc_001',
        'purchaseId': '', // Empty legacy value
        'sourceType': 'whole_stone',
        'consignedQuantity': 10.0,
        'brokerName': 'Aung Aung',
        'brokerPhone': '09123456789',
        'brokerAddress': 'Yangon',
        'createdAt': 1785033455125,
        'historicalData': {
          'purchaseName': 'Legacy Purchase',
          'purchaseDate': 1700000000,
          'originalSeller': 'Old Seller',
          'gemstoneType': '', // Empty legacy value
          'sourceType': 'whole_stone',
          'originalQuantity': 10.0,
          'originalWeight': 5.0,
          'capturedAt': 1700000000,
        },
      };

      final result = BackupDeserializers.deserializeBrokerConsignment(json);
      expect(result, isNotNull);
      expect(result!.purchaseId, equals(''));
      expect(result.historicalData.gemstoneType, equals(''));
    });

    // Test 2: Null purchaseId should deserialize as empty string
    test('Deserialize BrokerConsignment with null purchaseId', () {
      final json = {
        'id': 'bc_002',
        'purchaseId': null, // Null legacy value
        'sourceType': 'breakdown_item',
        'consignedQuantity': 5.0,
        'brokerName': 'Kyaw Kyaw',
        'brokerPhone': '09987654321',
        'brokerAddress': 'Mandalay',
        'createdAt': 1785033455126,
        'historicalData': {
          'purchaseName': 'Another Purchase',
          'purchaseDate': 1700000001,
          'originalSeller': '',
          'gemstoneType': null, // Null legacy value
          'sourceType': 'breakdown_item',
          'originalQuantity': 5.0,
          'originalWeight': 2.5,
          'capturedAt': 1700000001,
        },
      };

      final result = BackupDeserializers.deserializeBrokerConsignment(json);
      expect(result, isNotNull);
      expect(result!.purchaseId, equals(''));
      expect(result.historicalData.gemstoneType, equals(''));
    });

    // Test 3: Missing purchaseId should deserialize as empty string
    test('Deserialize BrokerConsignment with missing purchaseId', () {
      final json = {
        'id': 'bc_003',
        // purchaseId is completely missing
        'sourceType': 'whole_stone',
        'consignedQuantity': 15.0,
        'brokerName': 'Zaw Zaw',
        'brokerPhone': '09111111111',
        'brokerAddress': 'Naypyidaw',
        'createdAt': 1785033455127,
        'historicalData': {
          'purchaseName': 'Third Purchase',
          'purchaseDate': 1700000002,
          'originalSeller': 'Third Seller',
          'gemstoneType': 'Ruby', // Non-empty for this test
          'sourceType': 'whole_stone',
          'originalQuantity': 15.0,
          'originalWeight': 7.5,
          'capturedAt': 1700000002,
        },
      };

      final result = BackupDeserializers.deserializeBrokerConsignment(json);
      expect(result, isNotNull);
      expect(result!.purchaseId, equals(''));
    });

    // Test 4: Real record 1785033455125 with empty purchaseId and gemstoneType
    test('Deserialize real legacy record 1785033455125', () {
      final json = {
        'id': 'bc_1785033455125',
        'purchaseId': '', // Real legacy empty value
        'sourceType': 'whole_stone',
        'consignedQuantity': 20.0,
        'brokerName': 'Legacy Broker',
        'brokerPhone': '09000000000',
        'brokerAddress': 'Legacy Address',
        'createdAt': 1785033455125,
        'historicalData': {
          'purchaseName': 'Legacy Historical Purchase',
          'purchaseDate': 1700000000,
          'originalSeller': 'Legacy Seller',
          'gemstoneType': '', // Real legacy empty value
          'sourceType': 'whole_stone',
          'originalQuantity': 20.0,
          'originalWeight': 10.0,
          'capturedAt': 1700000000,
        },
      };

      final result = BackupDeserializers.deserializeBrokerConsignment(json);
      expect(result, isNotNull);
      expect(result!.id, equals('bc_1785033455125'));
      expect(result.purchaseId, equals(''));
      expect(result.historicalData.gemstoneType, equals(''));
    });

    // Test 5: Other required validations still fail correctly
    test('Fail when purchaseName is empty', () {
      final json = {
        'id': 'bc_004',
        'purchaseId': '', // Empty is OK
        'sourceType': 'whole_stone',
        'consignedQuantity': 10.0,
        'brokerName': 'Test Broker',
        'brokerPhone': '09222222222',
        'brokerAddress': 'Test Address',
        'createdAt': 1785033455128,
        'historicalData': {
          'purchaseName': '', // INVALID: empty required field
          'purchaseDate': 1700000003,
          'originalSeller': '',
          'gemstoneType': '', // Empty is OK
          'sourceType': 'whole_stone',
          'originalQuantity': 10.0,
          'originalWeight': 5.0,
          'capturedAt': 1700000003,
        },
      };

      final result = BackupDeserializers.deserializeBrokerConsignment(json);
      expect(result, isNull); // Should fail
    });

    // Test 6: Fail when sourceType is empty
    test('Fail when sourceType is empty', () {
      final json = {
        'id': 'bc_005',
        'purchaseId': '', // Empty is OK
        'sourceType': '', // INVALID: empty required field
        'consignedQuantity': 10.0,
        'brokerName': 'Test Broker',
        'brokerPhone': '09333333333',
        'brokerAddress': 'Test Address',
        'createdAt': 1785033455129,
        'historicalData': {
          'purchaseName': 'Valid Name',
          'purchaseDate': 1700000004,
          'originalSeller': '',
          'gemstoneType': '', // Empty is OK
          'sourceType': '', // INVALID: empty required field
          'originalQuantity': 10.0,
          'originalWeight': 5.0,
          'capturedAt': 1700000004,
        },
      };

      final result = BackupDeserializers.deserializeBrokerConsignment(json);
      expect(result, isNull); // Should fail
    });

    // Test 7: Fail when consignedQuantity is negative
    test('Fail when consignedQuantity is negative', () {
      final json = {
        'id': 'bc_006',
        'purchaseId': '', // Empty is OK
        'sourceType': 'whole_stone',
        'consignedQuantity': -5.0, // INVALID: negative quantity
        'brokerName': 'Test Broker',
        'brokerPhone': '09444444444',
        'brokerAddress': 'Test Address',
        'createdAt': 1785033455130,
        'historicalData': {
          'purchaseName': 'Valid Name',
          'purchaseDate': 1700000005,
          'originalSeller': '',
          'gemstoneType': '', // Empty is OK
          'sourceType': 'whole_stone',
          'originalQuantity': 10.0,
          'originalWeight': 5.0,
          'capturedAt': 1700000005,
        },
      };

      final result = BackupDeserializers.deserializeBrokerConsignment(json);
      expect(result, isNull); // Should fail
    });

    // Test 8: Fail when brokerName is empty
    test('Fail when brokerName is empty', () {
      final json = {
        'id': 'bc_007',
        'purchaseId': '', // Empty is OK
        'sourceType': 'whole_stone',
        'consignedQuantity': 10.0,
        'brokerName': '', // INVALID: empty required field
        'brokerPhone': '09555555555',
        'brokerAddress': 'Test Address',
        'createdAt': 1785033455131,
        'historicalData': {
          'purchaseName': 'Valid Name',
          'purchaseDate': 1700000006,
          'originalSeller': '',
          'gemstoneType': '', // Empty is OK
          'sourceType': 'whole_stone',
          'originalQuantity': 10.0,
          'originalWeight': 5.0,
          'capturedAt': 1700000006,
        },
      };

      final result = BackupDeserializers.deserializeBrokerConsignment(json);
      expect(result, isNull); // Should fail
    });
  });
}
