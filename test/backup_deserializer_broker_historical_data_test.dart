import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone_management/features/settings/data/backup_deserializers.dart';

/// Test for BrokerHistoricalData deserialization with empty/null originalSeller
/// 
/// Regression test for Phase 7 Broker Consignment Restore fix.
/// Ensures that originalSeller can be empty string without causing deserialization to fail.

void main() {
  group('BrokerHistoricalData Deserialization Tests', () {
    test('Deserialize with empty originalSeller should succeed', () {
      // ARRANGE
      final json = {
        'purchaseName': 'Purchase from Broker A',
        'purchaseDate': 1690000000,
        'originalSeller': '',  // Empty string - the fix case
        'gemstoneType': 'Ruby',
        'sourceType': 'whole_stone',
        'breakdownItemName': null,
        'originalQuantity': 10.0,
        'originalWeight': 50.5,
        'capturedAt': 1690100000,
      };

      // ACT
      final result = BackupDeserializers.deserializeBrokerHistoricalData(json);

      // ASSERT
      expect(result, isNotNull, reason: 'Should deserialize successfully with empty originalSeller');
      expect(result!.originalSeller, equals(''), reason: 'originalSeller should be empty string');
      expect(result.purchaseName, equals('Purchase from Broker A'));
      expect(result.gemstoneType, equals('Ruby'));
      expect(result.sourceType, equals('whole_stone'));
      expect(result.originalQuantity, equals(10.0));
      expect(result.originalWeight, equals(50.5));
    });

    test('Deserialize with null originalSeller should default to empty string', () {
      // ARRANGE
      final json = {
        'purchaseName': 'Purchase from Broker B',
        'purchaseDate': 1690000000,
        'originalSeller': null,  // Null - should default to empty string
        'gemstoneType': 'Sapphire',
        'sourceType': 'breakdown_item',
        'breakdownItemName': 'ပုတီး',
        'originalQuantity': 5.0,
        'originalWeight': 25.0,
        'capturedAt': 1690100000,
      };

      // ACT
      final result = BackupDeserializers.deserializeBrokerHistoricalData(json);

      // ASSERT
      expect(result, isNotNull, reason: 'Should deserialize successfully with null originalSeller');
      expect(result!.originalSeller, equals(''), reason: 'null originalSeller should default to empty string');
      expect(result.purchaseName, equals('Purchase from Broker B'));
      expect(result.gemstoneType, equals('Sapphire'));
      expect(result.sourceType, equals('breakdown_item'));
    });

    test('Deserialize with non-empty originalSeller should preserve value', () {
      // ARRANGE
      final json = {
        'purchaseName': 'Purchase from Broker C',
        'purchaseDate': 1690000000,
        'originalSeller': 'Seller Name',  // Non-empty - should be preserved
        'gemstoneType': 'Emerald',
        'sourceType': 'whole_stone',
        'breakdownItemName': null,
        'originalQuantity': 15.0,
        'originalWeight': 75.0,
        'capturedAt': 1690100000,
      };

      // ACT
      final result = BackupDeserializers.deserializeBrokerHistoricalData(json);

      // ASSERT
      expect(result, isNotNull, reason: 'Should deserialize successfully with non-empty originalSeller');
      expect(result!.originalSeller, equals('Seller Name'), reason: 'Non-empty originalSeller should be preserved');
      expect(result.purchaseName, equals('Purchase from Broker C'));
      expect(result.gemstoneType, equals('Emerald'));
    });

    test('Deserialize should still fail if purchaseName is empty', () {
      // ARRANGE
      final json = {
        'purchaseName': '',  // Empty - should still fail
        'purchaseDate': 1690000000,
        'originalSeller': '',
        'gemstoneType': 'Ruby',
        'sourceType': 'whole_stone',
        'breakdownItemName': null,
        'originalQuantity': 10.0,
        'originalWeight': 50.5,
        'capturedAt': 1690100000,
      };

      // ACT
      final result = BackupDeserializers.deserializeBrokerHistoricalData(json);

      // ASSERT
      expect(result, isNull, reason: 'Should fail when purchaseName is empty');
    });

    test('Deserialize should still fail if gemstoneType is empty', () {
      // ARRANGE
      final json = {
        'purchaseName': 'Purchase from Broker D',
        'purchaseDate': 1690000000,
        'originalSeller': '',
        'gemstoneType': '',  // Empty - should still fail
        'sourceType': 'whole_stone',
        'breakdownItemName': null,
        'originalQuantity': 10.0,
        'originalWeight': 50.5,
        'capturedAt': 1690100000,
      };

      // ACT
      final result = BackupDeserializers.deserializeBrokerHistoricalData(json);

      // ASSERT
      expect(result, isNull, reason: 'Should fail when gemstoneType is empty');
    });

    test('Deserialize should still fail if originalQuantity is negative', () {
      // ARRANGE
      final json = {
        'purchaseName': 'Purchase from Broker E',
        'purchaseDate': 1690000000,
        'originalSeller': '',
        'gemstoneType': 'Ruby',
        'sourceType': 'whole_stone',
        'breakdownItemName': null,
        'originalQuantity': -5.0,  // Negative - should still fail
        'originalWeight': 50.5,
        'capturedAt': 1690100000,
      };

      // ACT
      final result = BackupDeserializers.deserializeBrokerHistoricalData(json);

      // ASSERT
      expect(result, isNull, reason: 'Should fail when originalQuantity is negative');
    });

    test('Deserialize should still fail if capturedAt is negative', () {
      // ARRANGE
      final json = {
        'purchaseName': 'Purchase from Broker F',
        'purchaseDate': 1690000000,
        'originalSeller': '',
        'gemstoneType': 'Ruby',
        'sourceType': 'whole_stone',
        'breakdownItemName': null,
        'originalQuantity': 10.0,
        'originalWeight': 50.5,
        'capturedAt': -1,  // Negative - should still fail
      };

      // ACT
      final result = BackupDeserializers.deserializeBrokerHistoricalData(json);

      // ASSERT
      expect(result, isNull, reason: 'Should fail when capturedAt is negative');
    });

    test('Real-world case: Record key 1784997859314-35904 with empty originalSeller', () {
      // ARRANGE - Simulating the exact failing record from the backup
      final json = {
        'purchaseName': 'Broker Purchase',
        'purchaseDate': 1690000000,
        'originalSeller': '',  // The exact issue from the backup
        'gemstoneType': 'Ruby',
        'sourceType': 'whole_stone',
        'breakdownItemName': null,
        'originalQuantity': 10.0,
        'originalWeight': 50.0,
        'capturedAt': 1690100000,
      };

      // ACT
      final result = BackupDeserializers.deserializeBrokerHistoricalData(json);

      // ASSERT
      expect(result, isNotNull, reason: 'Record 1784997859314-35904 should deserialize successfully');
      expect(result!.originalSeller, equals(''));
      expect(result.purchaseName, equals('Broker Purchase'));
      expect(result.sourceType, equals('whole_stone'));
    });
  });
}
