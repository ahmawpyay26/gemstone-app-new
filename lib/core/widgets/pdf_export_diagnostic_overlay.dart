import 'package:flutter/material.dart';
import '../services/pdf_export_diagnostic.dart';

/// Persistent diagnostic overlay for PDF export flow
/// Shows current checkpoint, last completed checkpoint, exceptions, and stack traces
class PdfExportDiagnosticOverlay extends StatefulWidget {
  const PdfExportDiagnosticOverlay({Key? key}) : super(key: key);

  @override
  State<PdfExportDiagnosticOverlay> createState() => _PdfExportDiagnosticOverlayState();
}

class _PdfExportDiagnosticOverlayState extends State<PdfExportDiagnosticOverlay> {
  final diagnostic = PdfExportDiagnostic();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    diagnostic.addListener(_onDiagnosticChanged);
  }

  @override
  void dispose() {
    diagnostic.removeListener(_onDiagnosticChanged);
    super.dispose();
  }

  void _onDiagnosticChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!diagnostic.isActive) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: diagnostic.exceptionMessage != null ? Colors.red : Colors.green,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with CLOSE button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'PDF Export Diagnostic',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getResultColor(diagnostic.finalResult),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              diagnostic.finalResult,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => diagnostic.dismiss(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CLOSE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Current checkpoint (always visible)
                _buildCheckpointRow(
                  'Current:',
                  diagnostic.currentCheckpoint,
                  Colors.cyan,
                ),

                if (_isExpanded) ...[
                  const SizedBox(height: 8),
                  
                  // Final result details table
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Result Details:', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('• PDF Null: ${diagnostic.generatePdfReturnedNull ?? "N/A"}', style: TextStyle(color: Colors.white, fontSize: 10)),
                        Text('• File Exists: ${diagnostic.fileExists ?? "N/A"}', style: TextStyle(color: Colors.white, fontSize: 10)),
                        Text('• File Size: ${diagnostic.fileSize != null ? "${diagnostic.fileSize} bytes" : "N/A"}', style: TextStyle(color: Colors.white, fontSize: 10)),
                        Text('• Share Reached: ${diagnostic.shareReached}', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Last completed checkpoint
                  _buildCheckpointRow(
                    'Last:',
                    diagnostic.lastCompletedCheckpoint.isEmpty 
                        ? 'None' 
                        : diagnostic.lastCompletedCheckpoint,
                    Colors.green,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Exception message
                  if (diagnostic.exceptionMessage != null) ...[
                    _buildCheckpointRow(
                      'Error:',
                      diagnostic.exceptionMessage!,
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Stack trace line
                  if (diagnostic.stackTraceLine != null) ...[
                    _buildCheckpointRow(
                      'Stack:',
                      diagnostic.stackTraceLine!,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Checkpoint durations
                  if (diagnostic.checkpointDurations.isNotEmpty) ...[
                    Text(
                      'Timings:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...diagnostic.checkpointDurations.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '  ${e.key}: ${e.value.inMilliseconds}ms',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getResultColor(String result) {
    switch (result) {
      case 'SUCCESS':
        return Colors.green;
      case 'NULL RETURN':
      case 'EARLY RETURN':
        return Colors.orange;
      case 'EXCEPTION':
      case 'TIMEOUT':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildCheckpointRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
