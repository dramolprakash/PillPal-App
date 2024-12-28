
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  await NotificationService().initialize();
  
  runApp(const PillPalApp());
}

class PillPalApp extends StatelessWidget {
  const PillPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PillPal',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.login,
    );
  }
}