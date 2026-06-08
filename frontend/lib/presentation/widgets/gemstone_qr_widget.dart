import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';

class GemstoneQrWidget extends StatelessWidget {
  final String qrData;
  final String stoneName;

  const GemstoneQrWidget({
    Key? key,
    required this.qrData,
    required this.stoneName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200.0,
            gapless: false,
            embeddedImage: const AssetImage('assets/images/app_logo_small.png'),
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size(40, 40),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          stoneName,
          style: const TextStyle(
            color: AppTheme.primaryAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          qrData,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
