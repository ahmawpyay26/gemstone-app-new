import 'package:hive_flutter/hive_flutter.dart';
import 'local_db.dart';
import 'models.dart';
import '../services/password_service.dart';

class RBACTestData {
  static Future<void> initializeTestAccounts() async {
    try {
      final staffBox = Hive.box<StaffUser>(LocalDb.staffUsersBox);
      final roleBox = Hive.box<Role>(LocalDb.rolesBox);
      final permBox = Hive.box<Permission>(LocalDb.permissionsBox);

      // Check if test accounts already exist
      final existingStaff = staffBox.values.where((s) => s.username.startsWith('staff_')).toList();
      if (existingStaff.isNotEmpty) return;

      // Get permissions
      final dashboardPerm = permBox.values.firstWhere((p) => p.name == 'Dashboard', orElse: () => null as dynamic) as Permission?;
      final salesPerm = permBox.values.firstWhere((p) => p.name == 'Sales', orElse: () => null as dynamic) as Permission?;
      final inventoryPerm = permBox.values.firstWhere((p) => p.name == 'Inventory', orElse: () => null as dynamic) as Permission?;
      final purchasePerm = permBox.values.firstWhere((p) => p.name == 'Purchase Records', orElse: () => null as dynamic) as Permission?;
      final reportsPerm = permBox.values.firstWhere((p) => p.name == 'Reports', orElse: () => null as dynamic) as Permission?;

      // Create test roles
      final staffARole = Role(
        id: LocalDb.genId(),
        name: 'Staff A Role',
        permissionIds: [
          if (dashboardPerm != null) dashboardPerm.id,
          if (salesPerm != null) salesPerm.id,
        ],
        description: 'Dashboard + Sales access',
      );

      final staffBRole = Role(
        id: LocalDb.genId(),
        name: 'Staff B Role',
        permissionIds: [
          if (inventoryPerm != null) inventoryPerm.id,
          if (purchasePerm != null) purchasePerm.id,
        ],
        description: 'Inventory + Purchase access',
      );

      final staffCRole = Role(
        id: LocalDb.genId(),
        name: 'Staff C Role',
        permissionIds: [
          if (reportsPerm != null) reportsPerm.id,
        ],
        description: 'Reports only',
      );

      await roleBox.add(staffARole);
      await roleBox.add(staffBRole);
      await roleBox.add(staffCRole);

      // Create test staff accounts
      final staffA = StaffUser(
        id: LocalDb.genId(),
        fullName: 'Staff A',
        username: 'staff_a',
        passwordHash: PasswordService.hashPassword('password123'),
        phoneNumber: '09123456789',
        position: 'Sales Officer',
        roleId: staffARole.id,
        permissionIds: staffARole.permissionIds,
        isActive: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        createdBy: 'admin',
      );

      final staffB = StaffUser(
        id: LocalDb.genId(),
        fullName: 'Staff B',
        username: 'staff_b',
        passwordHash: PasswordService.hashPassword('password123'),
        phoneNumber: '09987654321',
        position: 'Inventory Officer',
        roleId: staffBRole.id,
        permissionIds: staffBRole.permissionIds,
        isActive: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        createdBy: 'admin',
      );

      final staffC = StaffUser(
        id: LocalDb.genId(),
        fullName: 'Staff C',
        username: 'staff_c',
        passwordHash: PasswordService.hashPassword('password123'),
        phoneNumber: '09555666777',
        position: 'Report Analyst',
        roleId: staffCRole.id,
        permissionIds: staffCRole.permissionIds,
        isActive: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        createdBy: 'admin',
      );

      await staffBox.add(staffA);
      await staffBox.add(staffB);
      await staffBox.add(staffC);

      print('✅ Test accounts initialized: staff_a, staff_b, staff_c (password: password123)');
    } catch (e) {
      print('Error initializing test accounts: $e');
    }
  }
}
