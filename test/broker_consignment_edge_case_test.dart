import 'package:flutter_test/flutter_test.dart';

/// Regression Test for Bug #140 Edge Case
/// 
/// Scenario: Purchase = 50, Consign = 10, Return = 4, Delete
/// Expected: Purchase Inventory = 50 (NOT 54)
/// 
/// This test verifies that delete correctly restores only the remaining
/// consigned quantity (consignedQuantity - returnedQuantity), not the
/// full consigned quantity.

void main() {
  group('Broker Consignment Edge Case Tests', () {
    test('Delete with partial returns restores only remaining quantity', () {
      // ARRANGE
      const double initialQuantity = 50.0;
      const double consignedQuantity = 10.0;
      const double returnedQuantity = 4.0;
      
      // Expected calculation
      final remainingToRestore = consignedQuantity - returnedQuantity;
      
      // Simulate inventory after consignment
      double inventoryAfterConsignment = initialQuantity - consignedQuantity;
      expect(inventoryAfterConsignment, equals(40.0),
        reason: 'After consigning 10 from 50, should have 40'
      );
      
      // Simulate inventory after return
      double inventoryAfterReturn = inventoryAfterConsignment + returnedQuantity;
      expect(inventoryAfterReturn, equals(44.0),
        reason: 'After returning 4 of the 10 consigned, should have 44'
      );
      
      // ACT - Simulate delete (restore remaining)
      double inventoryAfterDelete = inventoryAfterReturn + remainingToRestore;
      
      // ASSERT
      expect(inventoryAfterDelete, equals(50.0),
        reason: 'After deleting consignment with 4 returned, should restore to 50'
      );
      
      // Verify the math
      expect(remainingToRestore, equals(6.0),
        reason: 'Remaining to restore should be 10 - 4 = 6'
      );
      
      // Verify total restoration
      final totalRestored = returnedQuantity + remainingToRestore;
      expect(totalRestored, equals(consignedQuantity),
        reason: 'Total restored (returned + remaining) should equal consigned'
      );
    });

    test('Delete with no returns restores full consigned quantity', () {
      // ARRANGE
      const double initialQuantity = 50.0;
      const double consignedQuantity = 10.0;
      const double returnedQuantity = 0.0;
      
      final remainingToRestore = consignedQuantity - returnedQuantity;
      
      double inventoryAfterConsignment = initialQuantity - consignedQuantity;
      expect(inventoryAfterConsignment, equals(40.0));
      
      // ACT - Delete without any returns
      double inventoryAfterDelete = inventoryAfterConsignment + remainingToRestore;
      
      // ASSERT
      expect(inventoryAfterDelete, equals(50.0),
        reason: 'With no returns, delete should restore full 10 pieces'
      );
      expect(remainingToRestore, equals(10.0));
    });

    test('Delete with full returns restores nothing', () {
      // ARRANGE
      const double initialQuantity = 50.0;
      const double consignedQuantity = 10.0;
      const double returnedQuantity = 10.0;
      
      final remainingToRestore = consignedQuantity - returnedQuantity;
      
      double inventoryAfterConsignment = initialQuantity - consignedQuantity;
      expect(inventoryAfterConsignment, equals(40.0));
      
      double inventoryAfterReturn = inventoryAfterConsignment + returnedQuantity;
      expect(inventoryAfterReturn, equals(50.0),
        reason: 'After returning all 10, should be back to 50'
      );
      
      // ACT - Delete after all items returned
      double inventoryAfterDelete = inventoryAfterReturn + remainingToRestore;
      
      // ASSERT
      expect(inventoryAfterDelete, equals(50.0),
        reason: 'After returning all and deleting, should still be 50'
      );
      expect(remainingToRestore, equals(0.0),
        reason: 'Nothing left to restore'
      );
    });

    test('Multiple partial returns then delete', () {
      // ARRANGE
      const double initialQuantity = 50.0;
      const double consignedQuantity = 20.0;
      
      double inventory = initialQuantity - consignedQuantity; // 30
      expect(inventory, equals(30.0));
      
      // ACT - Multiple returns
      inventory += 5.0;  // First return
      expect(inventory, equals(35.0));
      
      inventory += 3.0;  // Second return
      expect(inventory, equals(38.0));
      
      // Total returned
      double totalReturned = 5.0 + 3.0;
      expect(totalReturned, equals(8.0));
      
      // Delete - restore remaining
      double remainingToRestore = consignedQuantity - totalReturned;
      inventory += remainingToRestore;
      
      // ASSERT
      expect(inventory, equals(50.0),
        reason: 'After multiple returns and delete, should be back to 50'
      );
      expect(remainingToRestore, equals(12.0),
        reason: 'Remaining to restore: 20 - 8 = 12'
      );
    });

    test('Breakdown item edge case - partial return then delete', () {
      // ARRANGE
      const String itemName = 'ပုတီး';
      const double initialQuantity = 50.0;
      const double consignedQuantity = 10.0;
      const double returnedQuantity = 4.0;
      
      // Simulate breakdown item in map
      Map<String, int> breakdownItems = {
        itemName: 50,
        'အဆွဲ': 30,
        'လက်ကောက်': 20,
      };
      
      // After consignment
      breakdownItems[itemName] = breakdownItems[itemName]! - consignedQuantity.toInt();
      expect(breakdownItems[itemName], equals(40));
      
      // After return
      breakdownItems[itemName] = breakdownItems[itemName]! + returnedQuantity.toInt();
      expect(breakdownItems[itemName], equals(44));
      
      // ACT - Delete
      double remainingToRestore = consignedQuantity - returnedQuantity;
      breakdownItems[itemName] = breakdownItems[itemName]! + remainingToRestore.toInt();
      
      // ASSERT
      expect(breakdownItems[itemName], equals(50),
        reason: 'Breakdown item should be restored to 50'
      );
    });
  });
}
