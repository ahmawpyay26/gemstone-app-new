import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/license_activation.dart';
import '../services/activation_service.dart';
import '../services/license_key_validator.dart';
import '../data/hive_activation_repository.dart';

/// License activation page for Phase 1A.
///
/// Shown when:
/// - Trial period has expired and no license is activated
/// - Clock rollback is detected
/// - License check fails
///
/// User must activate a license to proceed to login.
class LicenseActivationPage extends StatefulWidget {
  const LicenseActivationPage({Key? key}) : super(key: key);

  @override
  State<LicenseActivationPage> createState() => _LicenseActivationPageState();
}

class _LicenseActivationPageState extends State<LicenseActivationPage> {
  final _keyController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _activateLicense() async {
    final key = _keyController.text.trim();

    // Validate input
    final validationError = LicenseKeyValidator.getValidationError(key);
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Sanitize the input
      final sanitizedKey = LicenseKeyValidator.sanitizeInput(key);

      // Create activation
      final activation = LicenseActivation(
        activationKey: sanitizedKey,
        installationId: '', // Will be set by ActivationService
        activatedAt: DateTime.now().millisecondsSinceEpoch,
        activationStatus: 'activated',
        appVersion: '1.2.1',
        schemaVersion: 1,
      );

      // Save activation
      final repository = HiveActivationRepository();
      await repository.init();
      final activationService = ActivationService(repository: repository);
      final result = await activationService.activateLicense(sanitizedKey);
      
      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Activation failed: ${result.message}')),
          );
        }
        return;
      }

      // Success - navigate to login
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Activation failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('License Activation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Activate Your License',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Your trial period has ended. Please enter your activation key to continue using the application.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _keyController,
                decoration: InputDecoration(
                  labelText: 'Activation Key',
                  hintText: 'Enter your activation key',
                  errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.key),
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _activateLicense,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Activate'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Format: 20-50 characters (A-Z, 0-9, hyphens)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
