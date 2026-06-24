import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for secure password hashing and verification.
/// Uses SHA-256 with salt for password security.
class PasswordService {
  /// Generate a salt for password hashing
  static String _generateSalt() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now.toString().hashCode.abs();
    return '$now-$random';
  }

  /// Hash a password with a generated salt
  /// Returns: "hash:salt" format for storage
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$digest:$salt';
  }

  /// Verify a password against a stored hash
  /// storedHash should be in "hash:salt" format
  static bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;

      final salt = parts[1];
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);

      return digest.toString() == parts[0];
    } catch (e) {
      return false;
    }
  }

  /// Validate password strength
  /// Requirements:
  /// - At least 6 characters
  /// - At least one letter
  /// - At least one number (optional for simplicity)
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password ထည့်သွင်းပါ';
    }
    if (password.length < 6) {
      return 'Password သည် အနည်းဆုံး အက္ခရာ ၆ လုံး ရှိရမည်';
    }
    if (!password.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Password တွင် အက္ခရာ အနည်းဆုံး တစ်လုံး ရှိရမည်';
    }
    return null;
  }

  /// Validate username
  /// Requirements:
  /// - At least 3 characters
  /// - Only alphanumeric and underscore
  /// - No spaces
  static String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'အသုံးပြုသူအမည် ထည့်သွင်းပါ';
    }
    if (username.length < 3) {
      return 'အသုံးပြုသူအမည် သည် အနည်းဆုံး အက္ခရာ ၃ လုံး ရှိရမည်';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'အသုံးပြုသူအမည် တွင် အက္ခရာ၊ ဂဏန်းနှင့် underscore (_) သာ ပါဝင်နိုင်သည်';
    }
    return null;
  }
}
