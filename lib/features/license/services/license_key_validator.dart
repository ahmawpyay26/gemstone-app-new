/// Validates the format and structure of license activation keys.
/// This is the foundation for offline license verification.
///
/// Phase 1E: Format validation only
/// - No server communication
/// - No expiration checks
/// - No blacklist verification
/// - No device fingerprinting
class LicenseKeyValidator {
  /// Minimum length for a valid activation key
  static const int minKeyLength = 20;

  /// Maximum length for a valid activation key
  static const int maxKeyLength = 50;

  /// Pattern for valid activation key characters
  /// Allows: uppercase letters, digits, and hyphens
  static final RegExp _validKeyPattern = RegExp(r'^[A-Z0-9\-]+$');

  /// Validates an activation key format.
  ///
  /// Returns true if the key passes all format checks:
  /// - Not empty
  /// - Correct length (20-50 characters)
  /// - Valid characters (A-Z, 0-9, hyphens)
  /// - Proper structure (not all same character)
  ///
  /// Phase 1E: Format validation only
  /// - No real verification
  /// - No server communication
  /// - No expiration checks
  static bool isValidFormat(String key) {
    // Check if empty
    if (key.isEmpty) {
      return false;
    }

    // Check length
    if (key.length < minKeyLength || key.length > maxKeyLength) {
      return false;
    }

    // Check valid characters
    if (!_validKeyPattern.hasMatch(key)) {
      return false;
    }

    // Check for malformed keys (all same character)
    if (_isAllSameCharacter(key)) {
      return false;
    }

    return true;
  }

  /// Validates key and returns detailed error message if invalid.
  ///
  /// Returns null if key is valid, otherwise returns error message.
  static String? getValidationError(String key) {
    if (key.isEmpty) {
      return 'Activation key cannot be empty';
    }

    if (key.length < minKeyLength) {
      return 'Activation key is too short (minimum $minKeyLength characters)';
    }

    if (key.length > maxKeyLength) {
      return 'Activation key is too long (maximum $maxKeyLength characters)';
    }

    if (!_validKeyPattern.hasMatch(key)) {
      return 'Activation key contains invalid characters. Use only A-Z, 0-9, and hyphens';
    }

    if (_isAllSameCharacter(key)) {
      return 'Activation key format is invalid';
    }

    return null;
  }

  /// Check if all characters in the key are the same
  static bool _isAllSameCharacter(String key) {
    if (key.isEmpty) return false;
    final firstChar = key[0];
    return key.split('').every((char) => char == firstChar);
  }

  /// Sanitize user input by converting to uppercase and removing spaces
  static String sanitizeInput(String input) {
    return input.toUpperCase().replaceAll(' ', '');
  }
}
