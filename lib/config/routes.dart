import 'package:flutter/material.dart';

// Import screens (these will be created later)
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/medications/medication_list_screen.dart';
import '../screens/medications/medication_detail_screen.dart';
import '../screens/medications/add_medication_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/device/device_connection_screen.dart';
import '../screens/device/device_settings_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String medicationList = '/medications';
  static const String medicationDetail = '/medication-detail';
  static const String addMedication = '/add-medication';
  static const String profile = '/profile';
  static const String deviceConnection = '/device-connection';
  static const String deviceSettings = '/device-settings';

  // Route map
  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    schedule: (context) => const ScheduleScreen(),
    medicationList: (context) => const MedicationListScreen(),
    medicationDetail: (context) => (ModalRoute.of(context)!.settings.arguments as Map)['id'] != null 
      ? MedicationDetailScreen(id: (ModalRoute.of(context)!.settings.arguments as Map)['id'])
      : const MedicationListScreen(),
    addMedication: (context) => const AddMedicationScreen(),
    profile: (context) => const ProfileScreen(),
    deviceConnection: (context) => const DeviceConnectionScreen(),
    deviceSettings: (context) => const DeviceSettingsScreen(),
  };

  // Function to generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract the arguments
    final args = settings.arguments;

    switch (settings.name) {
      case medicationDetail:
        if (args is Map && args.containsKey('id')) {
          return MaterialPageRoute(builder: (_) => MedicationDetailScreen(id: args['id']));
        }
        return _errorRoute();
      default:
        return _errorRoute();
    }
  }

  // Error route
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Route not found!'),
        ),
      );
    });
  }
}