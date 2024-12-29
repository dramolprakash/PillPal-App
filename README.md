# PillPal - Smart Medication Dispenser App

PillPal is a Flutter-based mobile application that connects with a smart medication dispenser device to help users manage their medications effectively. The app provides medication reminders, tracks dosage, and ensures medication adherence through automated dispensing.

## Features

- 📱 User-friendly mobile interface
- 🔵 Bluetooth connectivity with dispenser device
- ⏰ Medication scheduling and reminders
- 📊 Medication tracking and history
- 🔔 Real-time notifications
- 👥 Emergency contact management
- 🔒 Secure user authentication
- 📈 Compliance monitoring

## Technical Requirements

- Flutter SDK >=3.6.0 <4.0.0
- Android SDK version 21 or higher
- Java Development Kit (JDK) version 17
- Bluetooth-enabled device

## Dependencies

```yaml
dependencies:
  flutter_blue_plus: ^1.31.16
  provider: ^6.0.5
  shared_preferences: ^2.2.0
  sqflite: ^2.3.0
  intl: ^0.18.1
  awesome_notifications: ^0.8.3
```

## Project Structure

```
lib/
├── config/
│   ├── theme.dart
│   └── routes.dart
├── models/
│   ├── user.dart
│   ├── medication.dart
│   └── device.dart
├── screens/
│   ├── auth/
│   ├── home/
│   ├── schedule/
│   ├── medications/
│   ├── profile/
│   └── device/
├── services/
│   ├── bluetooth_service.dart
│   └── notification_service.dart
└── utils/
    ├── constants.dart
    └── helpers.dart
```

## Setup Instructions

1. **Prerequisites**
   - Install Flutter SDK
   - Install Android Studio
   - Configure Android SDK
   - Set up a physical device or emulator

2. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/pillpal.git
   cd pillpal
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Android Settings**
   - Update `android/app/build.gradle`:
     ```gradle
     android {
         namespace "com.example.pillpal"
         compileSdkVersion 34
         minSdkVersion 21
         ...
     }
     ```

5. **Run the App**
   ```bash
   flutter run
   ```

## Bluetooth Configuration

The app requires specific permissions for Bluetooth functionality. These are automatically configured in the Android Manifest:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH" />
```

## Common Issues and Solutions

1. **Gradle Build Issues**
   - Clean the project: `flutter clean`
   - Delete build directories:
     ```bash
     cd android
     ./gradlew clean
     cd ..
     ```

2. **Bluetooth Connection Issues**
   - Ensure device Bluetooth is enabled
   - Check Android permissions
   - Verify minimum SDK version

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For support or queries, please open an issue in the repository.