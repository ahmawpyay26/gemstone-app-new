import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/diagnostic_log_service.dart';

class DebugLogPage extends StatefulWidget {
  const DebugLogPage({Key? key}) : super(key: key);

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  late String _logContent;

  @override
  void initState() {
    super.initState();
    _logContent = DiagnosticLogService.getCurrentLog();
  }

  void _copyLog() {
    Clipboard.setData(ClipboardData(text: _logContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ဒီဗတ်ဂ်လော့ကို ကူးယူပြီးပါပြီ')),
    );
  }

  void _clearLog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဒီဗတ်ဂ်လော့ ဖျက်မည်လား'),
        content: const Text('ဒီဗတ်ဂ်လော့အားလုံးကို ဖျက်လိုက်ပါ။'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('မဖျက်တော့ပါ'),
          ),
          ElevatedButton(
            onPressed: () {
              DiagnosticLogService.clearLog();
              setState(() {
                _logContent = '';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ဒီဗတ်ဂ်လော့ ဖျက်ပြီးပါပြီ')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
  }

  void _refreshLog() {
    setState(() {
      _logContent = DiagnosticLogService.getCurrentLog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ဒီဗတ်ဂ်လော့'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLog,
            tooltip: 'အဆင့်မြင့်ပြုပြင်',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLog,
            tooltip: 'ကူးယူ',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLog,
            tooltip: 'ဖျက်',
          ),
        ],
      ),
      body: _logContent.isEmpty
          ? const Center(
              child: Text('ဒီဗတ်ဂ်လော့ မရှိသေးပါ'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _logContent,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
    );
  }
}
