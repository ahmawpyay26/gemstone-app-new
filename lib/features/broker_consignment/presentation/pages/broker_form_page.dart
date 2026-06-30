import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BrokerFormPage extends StatefulWidget {
  final BrokerConsignment? existing;
  final dynamic hiveKey;

  const BrokerFormPage({
    Key? key,
    this.existing,
    this.hiveKey,
  }) : super(key: key);

  @override
  State<BrokerFormPage> createState() => _BrokerFormPageState();
}

class _BrokerFormPageState extends State<BrokerFormPage> {
  late TextEditingController _brokerNameCtrl;
  late TextEditingController _brokerPhoneCtrl;
  late TextEditingController _brokerAddressCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _brokerNameCtrl = TextEditingController(text: widget.existing?.brokerName ?? '');
    _brokerPhoneCtrl = TextEditingController(text: widget.existing?.brokerPhone ?? '');
    _brokerAddressCtrl = TextEditingController(text: widget.existing?.brokerAddress ?? '');
  }

  @override
  void dispose() {
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _brokerAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ပွဲစားအပ်စာရင်း'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _brokerNameCtrl,
              decoration: InputDecoration(
                labelText: 'ပွဲစားအမည်',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brokerPhoneCtrl,
              decoration: InputDecoration(
                labelText: 'ဖုန်းနံပါတ်',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brokerAddressCtrl,
              decoration: InputDecoration(
                labelText: 'လိပ်စာ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('သိမ်းဆည်းရန်'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
