
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/medications/medication_list_screen.dart';
import '../screens/medications/add_medication_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/device/device_screen.dart';

class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String medicationList = '/medications';
  static const String addMedication = '/medications/add';
  static const String profile = '/profile';
  static const String device = '/device';

  // Route map
  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    home: (context) => const HomeScreen(),
    schedule: (context) => const ScheduleScreen(),
    medicationList: (context) => const MedicationListScreen(),
    addMedication: (context) => const AddMedicationScreen(),
    profile: (context) => const ProfileScreen(),
    device: (context) => const DeviceScreen(),
  };
}