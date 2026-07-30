import 'package:flutter/material.dart';
import 'dart:developer' as dev;

/// Helper to display detailed error dialogs for mobile debugging
class ErrorDialogHelper {
  /// Show a detailed error dialog with exception info
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String step,
    required Object error,
    required StackTrace stackTrace,
    required String sourceFile,
  }) async {
    // Log to dev console as well
    dev.log(
      '[ERROR_DIALOG] STEP: $step\nERROR: $error\nFILE: $sourceFile\nSTACK:\n$stackTrace',
      name: 'ErrorDialogHelper',
    );

    // Extract first 30 lines of stack trace
    final stackLines = stackTrace.toString().split('\n');
    final truncatedStack = stackLines.take(30).join('\n');

    // Extract line number if available (usually in stack trace)
    String lineNumber = 'N/A';
    if (stackLines.isNotEmpty) {
      final firstLine = stackLines.first;
      // Try to extract line number from stack trace format
      final match = RegExp(r':(\d+)').firstMatch(firstLine);
      if (match != null) {
        lineNumber = match.group(1) ?? 'N/A';
      }
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            '❌ ERROR',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildErrorSection('STEP', step),
                const SizedBox(height: 12),
                _buildErrorSection('ERROR', error.toString()),
                const SizedBox(height: 12),
                _buildErrorSection('FILE', sourceFile),
                const SizedBox(height: 12),
                _buildErrorSection('LINE', lineNumber),
                const SizedBox(height: 12),
                _buildErrorSection('STACK TRACE', truncatedStack, isCode: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildErrorSection(
    String label,
    String value, {
    bool isCode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: isCode ? 'monospace' : 'Roboto',
              fontSize: isCode ? 10 : 12,
              color: Colors.black87,
            ),
            maxLines: isCode ? 35 : 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
