import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QrScannerPage extends StatelessWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('QR SCANNER'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Scanner Placeholder (Actual implementation would use mobile_scanner)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryAccent, width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Scanning Animation Line
                      const Positioned(
                        top: 50,
                        left: 20,
                        right: 20,
                        child: Divider(color: AppTheme.primaryAccent, thickness: 2),
                      ),
                      Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: AppTheme.primaryAccent.withOpacity(0.3),
                          size: 100,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'ကျောက်မျက်ရှိ QR Code ကို စကင်ဖတ်ပါ',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'အချက်အလက်များကို အလိုအလျောက်ပြသပေးပါမည်',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScannerAction(Icons.flash_on, 'Flash'),
                const SizedBox(width: 40),
                _buildScannerAction(Icons.image, 'Gallery'),
                const SizedBox(width: 40),
                _buildScannerAction(Icons.edit, 'Manual'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
