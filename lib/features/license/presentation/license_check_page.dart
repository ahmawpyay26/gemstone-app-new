import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/license_startup_service.dart';

/// License check page (splash screen) for Phase 1A.
///
/// Shown on app startup to check license/trial status.
/// Navigates to:
/// - Login page if trial is valid or license is activated
/// - License activation page if trial expired or error occurred
class LicenseCheckPage extends StatefulWidget {
  const LicenseCheckPage({Key? key}) : super(key: key);

  @override
  State<LicenseCheckPage> createState() => _LicenseCheckPageState();
}

class _LicenseCheckPageState extends State<LicenseCheckPage> {
  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    // Add a small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check license status
    final status = await LicenseStartupService.checkLicenseStatus();

    if (!mounted) return;

    // Navigate based on status
    switch (status) {
      case 'valid':
        // Trial valid or license activated - go to login
        context.go('/login');
        break;
      case 'trial_expired':
      case 'clock_rollback':
      case 'error':
        // Trial expired, clock rollback, or error - go to activation
        context.go('/license-activation');
        break;
      default:
        // Unknown status - go to activation for safety
        context.go('/license-activation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Checking License...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
