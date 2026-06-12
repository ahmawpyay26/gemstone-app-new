import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class BranchesPage extends StatelessWidget {
  const BranchesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ဆိုင်ခွဲ'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _branchCard(
            name: 'ပင်မဆိုင် (Head Office)',
            location: 'မန္တလေး',
            phone: '09-xxxxxxxxx',
          ),
          _branchCard(
            name: 'ဖားကန့် ဆိုင်ခွဲ',
            location: 'ဖားကန့်၊ ကချင်ပြည်နယ်',
            phone: '09-xxxxxxxxx',
          ),
          _branchCard(
            name: 'မိုးကုတ် ဆိုင်ခွဲ',
            location: 'မိုးကုတ်၊ မန္တလေးတိုင်း',
            phone: '09-xxxxxxxxx',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppTheme.primaryAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ဆိုင်ခွဲ အချက်အလက်များကို နောက်ပိုင်း update တွင် ပြင်ဆင်နိုင်ပါမည်။',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _branchCard(
      {required String name,
      required String location,
      required String phone}) {
    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
          child: const Icon(Icons.store, color: AppTheme.primaryAccent),
        ),
        title: Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.location_on,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(location, style: TextStyle(color: Colors.grey[400])),
            ]),
            Row(children: [
              const Icon(Icons.phone, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(phone, style: TextStyle(color: Colors.grey[400])),
            ]),
          ],
        ),
      ),
    );
  }
}
