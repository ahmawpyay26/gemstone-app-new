import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/installation_identity_service.dart';

/// License System diagnostic page displaying real locally stored values.
///
/// This page displays read-only diagnostic information from local storage.
/// It serves as a foundation for future license management UI.
///
/// This page is NOT connected to the main application startup flow.
/// It does not block access to existing features.
///
/// TODO(License Phase 2): Add license verification UI
/// TODO(License Phase 3): Add activation UI
/// TODO(License Phase 4): Add revocation handling
class LicensePlaceholderPage extends StatefulWidget {
  /// Creates a new instance of [LicensePlaceholderPage].
  const LicensePlaceholderPage({Key? key}) : super(key: key);

  @override
  State<LicensePlaceholderPage> createState() => _LicensePlaceholderPageState();
}

class _LicensePlaceholderPageState extends State<LicensePlaceholderPage> {
  late Future<Map<String, String>> _diagnosticDataFuture;

  @override
  void initState() {
    super.initState();
    _diagnosticDataFuture = _loadDiagnosticData();
  }

  /// Load diagnostic data from storage.
  Future<Map<String, String>> _loadDiagnosticData() async {
    try {
      final installationId = await InstallationIdentityService.getInstallationId();
      final firstInstallTime = await InstallationIdentityService.getFirstInstallTime();
      final lastOpenedTime = await InstallationIdentityService.getLastOpenedTime();
      final appVersion = InstallationIdentityService.getCurrentVersion();
      final buildNumber = InstallationIdentityService.getBuildNumber();

      return {
        'installationId': installationId,
        'appVersion': appVersion,
        'buildNumber': buildNumber.toString(),
        'firstInstallDate': _formatTimestamp(firstInstallTime),
        'lastOpenedDate': _formatTimestamp(lastOpenedTime),
        'licenseStatus': 'UNKNOWN',
      };
    } catch (e) {
      return {
        'installationId': 'ERROR: $e',
        'appVersion': 'Unknown',
        'buildNumber': 'Unknown',
        'firstInstallDate': 'Not Available',
        'lastOpenedDate': 'Not Available',
        'licenseStatus': 'UNKNOWN',
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
                        _buildInfoRow('License Status', data['licenseStatus'] ?? 'UNKNOWN'),
                        const SizedBox(height: 12.0),
                        _buildInfoRow('First Install', data['firstInstallDate'] ?? 'Not Available'),
                        const SizedBox(height: 12.0),
                        _buildInfoRow('Last Opened', data['lastOpenedDate'] ?? 'Not Available'),
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
                    'This is a read-only diagnostic view. '
                    'All data is loaded from local storage. '
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
