import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/installation_identity_service.dart';
import '../services/activation_service.dart';
import '../data/hive_activation_repository.dart';

/// License System diagnostic page displaying real locally stored values.
///
/// This page displays read-only diagnostic information from local storage.
/// It serves as a foundation for future license management UI.
///
/// Phase 1D: Added activation UI components (placeholder only)
/// - Activation Key input
/// - Activate button (disabled until valid input)
/// - Installation ID display (read-only)
/// - Activation Status display
///
/// This page is NOT connected to the main application startup flow.
/// It does not block access to existing features.
///
/// TODO(License Phase 2): Implement real activation verification
/// TODO(License Phase 3): Add license expiration handling
/// TODO(License Phase 4): Add revocation handling
class LicensePlaceholderPage extends StatefulWidget {
  /// Creates a new instance of [LicensePlaceholderPage].
  const LicensePlaceholderPage({Key? key}) : super(key: key);

  @override
  State<LicensePlaceholderPage> createState() => _LicensePlaceholderPageState();
}

class _LicensePlaceholderPageState extends State<LicensePlaceholderPage> {
  late Future<Map<String, String>> _diagnosticDataFuture;
  late ActivationService _activationService;
  final TextEditingController _activationKeyController = TextEditingController();
  bool _isActivating = false;
  String _activationMessage = '';

  @override
  void initState() {
    super.initState();
    _diagnosticDataFuture = _loadDiagnosticData();
    _initializeActivationService();
  }

  /// Initialize activation service
  void _initializeActivationService() {
    final repository = HiveActivationRepository();
    _activationService = ActivationService(
      repository: repository,
      identityService: InstallationIdentityService(),
    );
    repository.init();
  }

  /// Load diagnostic data from storage.
  Future<Map<String, String>> _loadDiagnosticData() async {
    try {
      final installationId = await InstallationIdentityService.getInstallationId();
      final firstInstallTime = await InstallationIdentityService.getFirstInstallTime();
      final lastOpenedTime = await InstallationIdentityService.getLastOpenedTime();
      final appVersion = InstallationIdentityService.getCurrentVersion();
      final buildNumber = InstallationIdentityService.getBuildNumber();
      final activationStatus = await _activationService.getActivationStatus();

      return {
        'installationId': installationId,
        'appVersion': appVersion,
        'buildNumber': buildNumber.toString(),
        'firstInstallDate': _formatTimestamp(firstInstallTime),
        'lastOpenedDate': _formatTimestamp(lastOpenedTime),
        'activationStatus': activationStatus,
      };
    } catch (e) {
      return {
        'installationId': 'ERROR: $e',
        'appVersion': 'Unknown',
        'buildNumber': 'Unknown',
        'firstInstallDate': 'Not Available',
        'lastOpenedDate': 'Not Available',
        'activationStatus': 'unknown',
      };
    }
  }

  /// Format timestamp to readable date string.
  String _formatTimestamp(int milliseconds) {
    if (milliseconds == 0) return 'Not Available';
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  /// Handle activation button press
  Future<void> _handleActivate() async {
    final activationKey = _activationKeyController.text.trim();

    if (activationKey.isEmpty) {
      setState(() {
        _activationMessage = 'Please enter an activation key';
      });
      return;
    }

    setState(() {
      _isActivating = true;
      _activationMessage = 'Activating...';
    });

    try {
      // TODO(License Phase 2): Implement real activation verification
      // For now, this is a placeholder that stores the activation locally
      final result = await _activationService.activateLicense(activationKey);

      setState(() {
        _isActivating = false;
        _activationMessage = result.message;
      });

      if (result.success) {
        // Refresh diagnostic data after successful activation
        setState(() {
          _diagnosticDataFuture = _loadDiagnosticData();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isActivating = false;
        _activationMessage = 'Activation error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _activationKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('License System'),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _diagnosticDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading diagnostic data: ${snapshot.error}'),
            );
          }

          final data = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'License System',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Version ${data['appVersion']}',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24.0),

                // Diagnostic Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnostic Information',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _buildInfoRow('Version', data['appVersion'] ?? 'Unknown'),
                        const SizedBox(height: 12.0),
                        _buildInfoRow('Build Number', data['buildNumber'] ?? 'Unknown'),
                        const SizedBox(height: 12.0),
                        _buildInfoRow('Installation ID', data['installationId'] ?? 'Not Available'),
                        const SizedBox(height: 12.0),
                        _buildInfoRow('Activation Status', data['activationStatus'] ?? 'unknown'),
                        const SizedBox(height: 12.0),
                        _buildInfoRow('First Install', data['firstInstallDate'] ?? 'Not Available'),
                        const SizedBox(height: 12.0),
                        _buildInfoRow('Last Opened', data['lastOpenedDate'] ?? 'Not Available'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Activation Section (Phase 1D)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'License Activation',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Installation ID Display (Read-only)
                        const Text(
                          'Installation ID',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                            color: Colors.grey.withOpacity(0.05),
                          ),
                          child: Text(
                            data['installationId'] ?? 'Not Available',
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Activation Key Input
                        const Text(
                          'Activation Key',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextField(
                          controller: _activationKeyController,
                          decoration: InputDecoration(
                            hintText: 'Enter activation key',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 12.0,
                            ),
                          ),
                          enabled: !_isActivating,
                        ),
                        const SizedBox(height: 16.0),

                        // Activate Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _activationKeyController.text.isEmpty || _isActivating
                                ? null
                                : _handleActivate,
                            child: _isActivating
                                ? const SizedBox(
                                    height: 20.0,
                                    width: 20.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text('Activate'),
                          ),
                        ),

                        // Activation Status Message
                        if (_activationMessage.isNotEmpty) ...[
                          const SizedBox(height: 12.0),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              _activationMessage,
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Copy Installation ID Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _copyInstallationId(data['installationId'] ?? ''),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Installation ID'),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Info Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    border: Border.all(color: Colors.blue, width: 1.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: const Text(
                    'Phase 1D: Activation UI is a placeholder. '
                    'No real activation verification is performed. '
                    'All data is stored locally. '
                    'No business logic is executed on this page.',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a single info row with label and value.
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  /// Copy installation ID to clipboard.
  void _copyInstallationId(String installationId) {
    if (installationId.isEmpty || installationId == 'Not Available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Installation ID not available')),
      );
      return;
    }

    // TODO(License Phase 1C): Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $installationId')),
    );
  }
}
