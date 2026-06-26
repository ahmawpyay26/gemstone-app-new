import 'package:hive_flutter/hive_flutter.dart';
import '../local/local_db.dart';
import '../local/models.dart';
import 'permission_service.dart';

class AuditService {
  static const String createUser = 'CREATE_USER';
  static const String updateUser = 'UPDATE_USER';
  static const String deleteUser = 'DELETE_USER';
  static const String login = 'LOGIN';
  static const String logout = 'LOGOUT';
  static const String passwordReset = 'PASSWORD_RESET';
  static const String accountDisabled = 'ACCOUNT_DISABLED';
  static const String accountEnabled = 'ACCOUNT_ENABLED';

  /// Log user action
  static Future<void> log({
    required String action,
    String? targetUserId,
    String? targetUserName,
    String? details,
  }) async {
    try {
      final auditBox = Hive.box<AuditLog>(LocalDb.auditLogsBox);
      final currentUser = PermissionService.getCurrentUser();
      final currentUserName = PermissionService.getCurrentUserName();

      final auditLog = AuditLog(
        id: LocalDb.genId(),
        action: action,
        saleId: null,
        gemstoneId: null,
        gemstoneName: null,
        quantity: null,
        amount: null,
        userId: currentUser is AppUser ? currentUser.id : (currentUser is StaffUser ? currentUser.id : 'system'),
        userName: currentUserName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: _buildDetails(action, targetUserId, targetUserName, details),
      );

      await auditBox.add(auditLog);
    } catch (e) {
      print('Error logging audit: $e');
    }
  }

  static String _buildDetails(
    String action,
    String? targetUserId,
    String? targetUserName,
    String? details,
  ) {
    final buffer = StringBuffer();

    switch (action) {
      case createUser:
        buffer.write('Created user: $targetUserName ($targetUserId)');
        break;
      case updateUser:
        buffer.write('Updated user: $targetUserName ($targetUserId)');
        break;
      case deleteUser:
        buffer.write('Deleted user: $targetUserName ($targetUserId)');
        break;
      case login:
        buffer.write('Logged in');
        break;
      case logout:
        buffer.write('Logged out');
        break;
      case passwordReset:
        buffer.write('Password reset for: $targetUserName');
        break;
      case accountDisabled:
        buffer.write('Account disabled: $targetUserName');
        break;
      case accountEnabled:
        buffer.write('Account enabled: $targetUserName');
        break;
      default:
        buffer.write(details ?? action);
    }

    return buffer.toString();
  }
}
