import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:gemstone_management/core/local/local_db.dart';

/// Verifies the core RBAC fix: the default Super Admin (admin/admin123) must
/// ALWAYS pass every permission check, so Edit/Delete/Restore for Purchase and
/// Sale are enabled. Staff sessions must NOT pass admin-only checks.
void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(dir.path);
    await Hive.openBox(LocalDb.sessionBox);
  });

  tearDown(() async {
    await Hive.box(LocalDb.sessionBox).clear();
  });

  void allPermissionsTrue() {
    expect(LocalDb.isCurrentUserSuperAdmin(), isTrue);
    expect(LocalDb.canEditPurchase(), isTrue);
    expect(LocalDb.canDeletePurchase(), isTrue);
    expect(LocalDb.canEditSale(), isTrue);
    expect(LocalDb.canDeleteSale(), isTrue);
    expect(LocalDb.canRestoreSale(), isTrue);
  }

  group('Super Admin permissions', () {
    test('Exactly the admin/admin123 login session -> all permissions TRUE',
        () {
      // Mirror exactly what LocalDb.saveSession(appUser) writes for admin.
      final s = Hive.box(LocalDb.sessionBox);
      s.put('userId', 'u1');
      s.put('userName', 'Admin');
      s.put('userEmail', 'admin@gemstone.com');
      s.put('userUsername', 'admin');
      s.put('userRole', 'admin'); // normalized in saveSession()
      s.put('userType', 'AppUser');
      s.put('loggedIn', true);

      allPermissionsTrue();
    });

    test('username == "admin" alone -> all permissions TRUE', () {
      final s = Hive.box(LocalDb.sessionBox);
      s.put('userUsername', 'admin');
      s.put('loggedIn', true);
      allPermissionsTrue();
    });

    test('role == "super_admin" alone -> all permissions TRUE', () {
      final s = Hive.box(LocalDb.sessionBox);
      s.put('userRole', 'super_admin');
      s.put('loggedIn', true);
      allPermissionsTrue();
    });

    test('userType == "AppUser" alone -> all permissions TRUE', () {
      final s = Hive.box(LocalDb.sessionBox);
      s.put('userType', 'AppUser');
      s.put('loggedIn', true);
      allPermissionsTrue();
    });
  });

  group('Staff permissions', () {
    test('StaffUser session -> all admin-only checks FALSE', () {
      final s = Hive.box(LocalDb.sessionBox);
      s.put('userId', 'staffA');
      s.put('userName', 'Staff A');
      s.put('userUsername', 'staff_a');
      s.put('userRole', 'staff');
      s.put('userType', 'StaffUser');
      s.put('loggedIn', true);

      expect(LocalDb.isCurrentUserSuperAdmin(), isFalse);
      expect(LocalDb.canEditPurchase(), isFalse);
      expect(LocalDb.canDeletePurchase(), isFalse);
      expect(LocalDb.canEditSale(), isFalse);
      expect(LocalDb.canDeleteSale(), isFalse);
      expect(LocalDb.canRestoreSale(), isFalse);
    });

    test('No session -> not super admin', () {
      expect(LocalDb.isCurrentUserSuperAdmin(), isFalse);
      expect(LocalDb.canEditPurchase(), isFalse);
    });
  });
}
