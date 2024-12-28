// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillpal/main.dart';
import 'package:pillpal/screens/auth/login_screen.dart';

void main() {
  testWidgets('PillPal app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const PillPalApp());

    // Verify that the login screen is shown first
    expect(find.byType(LoginScreen), findsOneWidget);
    
    // Verify that login form elements are present
    expect(find.text('PillPal'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });
}