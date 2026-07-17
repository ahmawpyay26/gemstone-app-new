import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gemstone_management/core/rca/rca_log_collector.dart';

/// Temporary RCA Debug Logs screen for instrumentation analysis
/// This page displays captured [HIVE-LOOKUP-*] and other RCA logs
class RCADebugLogsPage extends StatefulWidget {
  const RCADebugLogsPage({Key? key}) : super(key: key);

  @override
  State<RCADebugLogsPage> createState() => _RCADebugLogsPageState();
}

class _RCADebugLogsPageState extends State<RCADebugLogsPage> {
  late RCALogCollector _logCollector;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _logCollector = RCALogCollector();
    _scrollController = ScrollController();
    // Auto-scroll to bottom when new logs arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyLogs() {
    final logsText = _logCollector.getAllLogsAsString();
    Clipboard.setData(ClipboardData(text: logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs?'),
        content: const Text('Are you sure you want to clear all RCA logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _logCollector.clearLogs();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _logCollector.getFormattedLogs();
    final logCount = _logCollector.getLogCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RCA Debug Logs'),
        subtitle: Text('$logCount log entries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Copy All Logs',
            onPressed: _copyLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Logs',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No RCA logs captured yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perform a Broker Consignment operation to capture logs',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final isHiveLookup = log.contains('HIVE_LOOKUP');
                final isError = log.contains('NOT-FOUND') || log.contains('ERROR');
                final isSuccess = log.contains('FOUND') || log.contains('SAVED');

                Color backgroundColor = Colors.grey[100]!;
                Color textColor = Colors.black87;

                if (isHiveLookup) {
                  backgroundColor = Colors.blue[50]!;
                  textColor = Colors.blue[900]!;
                }
                if (isError) {
                  backgroundColor = Colors.red[50]!;
                  textColor = Colors.red[900]!;
                }
                if (isSuccess) {
                  backgroundColor = Colors.green[50]!;
                  textColor = Colors.green[900]!;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(
                      left: BorderSide(
                        color: isError
                            ? Colors.red
                            : isSuccess
                                ? Colors.green
                                : Colors.blue,
                        width: 3,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    log,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
