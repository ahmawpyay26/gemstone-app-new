import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/local/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalDb.init();
  } catch (e) {
    debugPrint('LocalDb init error: $e');
  }
  runApp(const GemstoneManagementApp());
}

class GemstoneManagementApp extends StatelessWidget {
  const GemstoneManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gemstone Management',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
