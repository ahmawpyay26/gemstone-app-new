import '../local/local_db.dart';
import '../local/models.dart';
import 'password_service.dart';

/// Service for authentication operations.
/// Handles login, logout, password changes, and username changes.
class AuthService {
  /// Login with username and password
  /// Returns user if successful, null if credentials are invalid
  static AppUser? login(String username, String password) {
    return LocalDb.loginWithUsername(username, password);
  }

  /// Change password for current user
  /// Returns true if successful, false otherwise
  static Future<bool> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get current user
      final user = LocalDb.getUserById(userId);
      if (user == null) return false;

      // Verify current password
      if (!PasswordService.verifyPassword(currentPassword, user.passwordHash)) {
        return false;
      }

      // Validate new password
      final validationError = PasswordService.validatePassword(newPassword);
      if (validationError != null) {
        return false;
      }

      // Update password hash
      user.passwordHash = PasswordService.hashPassword(newPassword);
      user.password = ''; // Clear legacy plaintext password

      // Save updated user
      return await LocalDb.updateUser(user);
    } catch (e) {
      return false;
    }
  }

  /// Change username for current user
  /// Returns true if successful, false otherwise
  static Future<bool> changeUsername({
    required String userId,
    required String newUsername,
  }) async {
    try {
      // Get current user
      final user = LocalDb.getUserById(userId);
      if (user == null) return false;

      // Validate new username
      final validationError = PasswordService.validateUsername(newUsername);
      if (validationError != null) {
        return false;
      }

      // Check if username is already taken
      final existingUser = LocalDb.getUserByUsername(newUsername);
      if (existingUser != null && existingUser.id != userId) {
        return false; // Username already taken
      }

      // Update username
      user.username = newUsername;

      // Save updated user
      return await LocalDb.updateUser(user);
    } catch (e) {
      return false;
    }
  }

  /// Logout current user
  /// Clears session data
  static void logout() {
    LocalDb.logout();
    LocalDb.clearRememberedCredentials();
  }

  /// Get current logged-in user
  static AppUser? getCurrentUser() {
    final currentUserData = LocalDb.currentUser();
    final userId = currentUserData['id'] as String;
    if (userId.isEmpty) return null;
    return LocalDb.getUserById(userId);
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return LocalDb.isLoggedIn();
  }
}
