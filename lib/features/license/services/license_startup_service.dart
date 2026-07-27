import 'package:flutter/foundation.dart';
import '../models/license_identity.dart';
import '../data/local_license_repository.dart';
import 'installation_identity_service.dart';

/// License startup service for Phase 1A.
///
/// Responsibilities:
/// - Check license/trial status on app startup
/// - Calculate trial validity (30 days from first app open)
/// - Detect clock rollback attacks
/// - Determine if app should show login or license activation page
///
/// Phase 1A: Startup flow foundation only
/// - No server communication
/// - No encryption
/// - No device binding
/// - No online verification
class LicenseStartupService {
  /// Trial period in days
  static const int trialPeriodDays = 30;

  /// Private constructor to prevent instantiation
  LicenseStartupService._();

  /// Check license/trial status on app startup.
  ///
  /// Returns:
  /// - 'valid' if trial is still valid or license is activated
  /// - 'trial_expired' if trial period has ended and no license is activated
  /// - 'clock_rollback' if device date was rolled back
  /// - 'error' if license check fails
  ///
  /// This method should be called during app initialization,
  /// before showing the login page.
  static Future<String> checkLicenseStatus() async {
    try {
      // Get or create installation identity
      final identity = await InstallationIdentityService.getOrCreateIdentity();

      if (identity.installationId == 'ERROR-STORAGE-FAILED') {
        // Storage failed - show activation page for safety
        return 'error';
      }

      // Check for clock rollback
      final clockRollbackDetected = await _detectClockRollback();
      if (clockRollbackDetected) {
        return 'clock_rollback';
      }

      // Check if license is activated
      final localLicenseRepo = LocalLicenseRepository();
      final isActivated = await localLicenseRepo.isActivated();

      if (isActivated) {
        // License is activated
        return 'valid';
      }

      // Check trial validity
      final isTrialValid = await _isTrialValid(identity.firstInstallTime);
      if (isTrialValid) {
        return 'valid';
      }

      // Trial expired and no license
      return 'trial_expired';
    } catch (e) {
      // Safe failure - show activation page
      debugPrint('License check error: $e');
      return 'error';
    }
  }

  /// Check if trial is still valid.
  ///
  /// Trial is valid if:
  /// - Current date is within 30 days from first app open
  ///
  /// Parameters:
  /// - firstInstallTime: Timestamp (milliseconds since epoch) of first app open
  ///
  /// Returns true if trial is valid, false if expired
  static Future<bool> _isTrialValid(int firstInstallTime) async {
    try {
      if (firstInstallTime == 0) {
        // No installation date - should not happen, but treat as error
        return false;
      }

      final now = DateTime.now();
      final firstInstallDate = DateTime.fromMillisecondsSinceEpoch(firstInstallTime);

      // Calculate days elapsed
      final daysElapsed = now.difference(firstInstallDate).inDays;

      // Trial is valid if <= 30 days
      return daysElapsed <= trialPeriodDays;
    } catch (e) {
      debugPrint('Trial calculation error: $e');
      return false;
    }
  }

  /// Detect clock rollback attack.
  ///
  /// Clock rollback is detected if:
  /// - Current date is before last opened date
  ///
  /// This prevents users from extending trial by setting device date backward.
  ///
  /// Returns true if rollback detected, false otherwise
  static Future<bool> _detectClockRollback() async {
    try {
      final lastOpenedTime = await InstallationIdentityService.getLastOpenedTime();

      if (lastOpenedTime == 0) {
        // First launch, no previous time to compare
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      // If current time is before last opened time, clock was rolled back
      if (now < lastOpenedTime) {
        debugPrint('Clock rollback detected: now=$now, lastOpened=$lastOpenedTime');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Clock rollback detection error: $e');
      // Safe failure - treat as no rollback
      return false;
    }
  }

  /// Get remaining trial days.
  ///
  /// Returns the number of days remaining in the trial period.
  /// Returns 0 if trial has expired.
  /// Returns -1 if license is activated or error occurred.
  static Future<int> getRemainingTrialDays() async {
    try {
      // Check if license is activated
      final localLicenseRepo = LocalLicenseRepository();
      final isActivated = await localLicenseRepo.isActivated();

      if (isActivated) {
        // License is activated
        return -1;
      }

      // Get first install time
      final firstInstallTime = await InstallationIdentityService.getFirstInstallTime();

      if (firstInstallTime == 0) {
        return -1;
      }

      final now = DateTime.now();
      final firstInstallDate = DateTime.fromMillisecondsSinceEpoch(firstInstallTime);

      // Calculate days elapsed
      final daysElapsed = now.difference(firstInstallDate).inDays;

      // Calculate remaining days
      final remaining = trialPeriodDays - daysElapsed;

      return remaining > 0 ? remaining : 0;
    } catch (e) {
      debugPrint('Remaining trial days calculation error: $e');
      return -1;
    }
  }

  /// Get trial start date.
  ///
  /// Returns the date when the trial period started (first app open).
  /// Returns null if no trial has started.
  static Future<DateTime?> getTrialStartDate() async {
    try {
      final firstInstallTime = await InstallationIdentityService.getFirstInstallTime();

      if (firstInstallTime == 0) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(firstInstallTime);
    } catch (e) {
      debugPrint('Trial start date error: $e');
      return null;
    }
  }

  /// Get trial end date.
  ///
  /// Returns the date when the trial period will end.
  /// Returns null if no trial has started.
  static Future<DateTime?> getTrialEndDate() async {
    try {
      final startDate = await getTrialStartDate();

      if (startDate == null) {
        return null;
      }

      return startDate.add(Duration(days: trialPeriodDays));
    } catch (e) {
      debugPrint('Trial end date error: $e');
      return null;
    }
  }
}
