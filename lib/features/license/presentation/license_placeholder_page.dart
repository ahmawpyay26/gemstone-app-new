import 'package:flutter/material.dart';
import '../models/diagnostic_info.dart';

/// Placeholder page for the License System.
///
/// This page displays read-only placeholder diagnostic information.
/// It serves as a foundation for future license management UI.
///
/// This page is NOT connected to the main application startup flow.
/// It does not block access to existing features.
///
/// TODO(License Phase 1B): Connect to InstallationIdentityService
/// TODO(License Phase 2): Add real diagnostic data loading
/// TODO(License Phase 3): Add license verification UI
class LicensePlaceholderPage extends StatelessWidget {
  /// Creates a new instance of [LicensePlaceholderPage].
  const LicensePlaceholderPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO(License Phase 1B): Load real diagnostic info from InstallationIdentityService
    final diagnosticInfo = DiagnosticInfo.placeholder();

    return Scaffold(
      appBar: AppBar(
        title: const Text('License System'),
      ),
      body: SingleChildScrollView(
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
              'Version ${diagnosticInfo.appVersion}',
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
                    _buildInfoRow('Installation ID', diagnosticInfo.installationId),
                    const SizedBox(height: 12.0),
                    _buildInfoRow('License Status', diagnosticInfo.licenseStatus),
                    const SizedBox(height: 12.0),
                    _buildInfoRow('App Version', diagnosticInfo.appVersion),
                    const SizedBox(height: 12.0),
                    _buildInfoRow('Build Number', diagnosticInfo.buildNumber),
                    const SizedBox(height: 12.0),
                    _buildInfoRow('First Install', diagnosticInfo.firstInstallDate),
                    const SizedBox(height: 12.0),
                    _buildInfoRow('Last Opened', diagnosticInfo.lastOpenedDate),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0),

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
                'No business logic is executed on this page. '
                'All data is placeholder information for Phase 1B.',
                style: TextStyle(fontSize: 12.0),
              ),
            ),
          ],
        ),
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
}
