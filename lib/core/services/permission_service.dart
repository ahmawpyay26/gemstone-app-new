import 'package:hive_flutter/hive_flutter.dart';
import '../local/local_db.dart';
import '../local/models.dart';

class PermissionService {
  static const String currentUserKey = 'currentUser';
  static const String currentUserTypeKey = 'currentUserType'; // 'AppUser' or 'StaffUser'

  /// Check if current user has a specific permission
  static bool hasPermission(String permissionName) {
    try {
      final sessionBox = Hive.box(LocalDb.sessionBox);
      final userType = sessionBox.get(currentUserTypeKey) as String?;

      if (userType == 'AppUser') {
        // Super Admin (AppUser with role 'super_admin') has all permissions
        return true;
      } else if (userType == 'StaffUser') {
        final staffId = sessionBox.get(currentUserKey) as String?;
        if (staffId == null) return false;

        final staffBox = Hive.box<StaffUser>(LocalDb.staffUsersBox);
        final staff = staffBox.values.firstWhere(
          (s) => s.id == staffId,
          orElse: () => null as dynamic,
        ) as StaffUser?;

        if (staff == null || !staff.isActive) return false;

        // Check if staff has this permission directly
        if (staff.permissionIds.contains(permissionName)) return true;

        // Check if staff's role has this permission
        final roleBox = Hive.box<Role>(LocalDb.rolesBox);
        final role = roleBox.values.firstWhere(
          (r) => r.id == staff.roleId,
          orElse: () => null as dynamic,
        ) as Role?;

        if (role != null) {
          final permBox = Hive.box<Permission>(LocalDb.permissionsBox);
          final perm = permBox.values.firstWhere(
            (p) => p.name == permissionName,
            orElse: () => null as dynamic,
          ) as Permission?;

          if (perm != null && role.permissionIds.contains(perm.id)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get current logged-in user (AppUser or StaffUser)
  static dynamic getCurrentUser() {
    try {
      final sessionBox = Hive.box(LocalDb.sessionBox);
      final userType = sessionBox.get(currentUserTypeKey) as String?;
      final userId = sessionBox.get(currentUserKey) as String?;

      if (userId == null) return null;

      if (userType == 'AppUser') {
        final userBox = Hive.box<AppUser>(LocalDb.usersBox);
        return userBox.values.firstWhere(
          (u) => u.id == userId,
          orElse: () => null as dynamic,
        ) as AppUser?;
      } else if (userType == 'StaffUser') {
        final staffBox = Hive.box<StaffUser>(LocalDb.staffUsersBox);
        return staffBox.values.firstWhere(
          (s) => s.id == userId,
          orElse: () => null as dynamic,
        ) as StaffUser?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current user's name
  static String getCurrentUserName() {
    try {
      final user = getCurrentUser();
      if (user is AppUser) return user.name;
      if (user is StaffUser) return user.fullName;
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Check if current user is Super Admin
  static bool isSuperAdmin() {
    try {
      final sessionBox = Hive.box(LocalDb.sessionBox);
      final userType = sessionBox.get(currentUserTypeKey) as String?;
      return userType == 'AppUser';
    } catch (e) {
      return false;
    }
  }

  /// Get list of accessible pages for current user
  static List<String> getAccessiblePages() {
    final pages = <String>[];
    final permissionNames = [
      'Dashboard',
      'Inventory',
      'Purchase Records',
      'Sales',
      'Expenses',
      'Workers',
      'Customers',
      'Reports',
      'Audit Log',
      'Settings',
    ];

    for (final perm in permissionNames) {
      if (hasPermission(perm)) {
        pages.add(perm);
      }
    }

    return pages;
  }

  /// Set current logged-in user
  static Future<void> setCurrentUser(dynamic user, String userType) async {
    final sessionBox = Hive.box(LocalDb.sessionBox);
    final userId = user is AppUser ? user.id : (user is StaffUser ? user.id : null);

    if (userId != null) {
      await sessionBox.put(currentUserKey, userId);
      await sessionBox.put(currentUserTypeKey, userType);
    }
  }

  /// Clear current session
  static Future<void> logout() async {
    final sessionBox = Hive.box(LocalDb.sessionBox);
    await sessionBox.delete(currentUserKey);
    await sessionBox.delete(currentUserTypeKey);
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    try {
      final sessionBox = Hive.box(LocalDb.sessionBox);
      return sessionBox.containsKey(currentUserKey);
    } catch (e) {
      return false;
    }
  }
}
