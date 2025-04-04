import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'package:intl/intl.dart';

class NotificationService {
  // Channel keys
  static const String medicationChannelKey = 'medication_channel';
  static const String deviceChannelKey = 'device_channel';
  
  // Notification IDs
  static const int medicationReminderId = 1;
  static const int medicationMissedId = 2;
  static const int deviceLowBatteryId = 3;
  static const int deviceDisconnectedId = 4;
  
  // Initialize notifications
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null, // No default icon
      [
        NotificationChannel(
          channelKey: medicationChannelKey,
          channelName: 'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          soundSource: 'resource://raw/medication_reminder',
        ),
        NotificationChannel(
          channelKey: deviceChannelKey,
          channelName: 'Device Alerts',
          channelDescription: 'Notifications for device status',
          defaultColor: Colors.orange,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );
    
    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }
  
  // Schedule medication reminder
  static Future<void> scheduleMedicationReminder(Medication medication, Schedule schedule) async {
    final now = DateTime.now();
    final notificationId = int.parse('${medication.id}${schedule.id}'.padRight(5, '0'));
    
    // Format time for notification content
    final timeFormat = DateFormat('h:mm a');
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      schedule.timeOfDay.hour,
      schedule.timeOfDay.minute,
    );
    final formattedTime = timeFormat.format(dateTime);
    
    // Schedule for each day in the schedule
    for (int dayOfWeek in schedule.daysOfWeek) {
      // Calculate next occurrence
      DateTime nextOccurrence = _getNextOccurrence(schedule.timeOfDay, dayOfWeek);
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId + dayOfWeek,
          channelKey: medicationChannelKey,
          title: 'Time to take ${medication.name}',
          body: 'Take ${medication.dosage} ${medication.dosageUnit.name} at $formattedTime\n${medication.instructions}',
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          weekday: dayOfWeek,
          hour: schedule.timeOfDay.hour,
          minute: schedule.timeOfDay.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'TAKEN',
            label: 'TAKEN',
            color: Colors.green,
          ),
          NotificationActionButton(
            key: 'SNOOZE',
            label: 'SNOOZE',
            color: Colors.blue,
          ),
        ],
      );
    }
  }
  
  // Send missed medication notification
  static Future<void> sendMissedMedicationNotification(Medication medication, Schedule schedule) async {
    final notificationId = int.parse('${medication.id}${schedule.id}${medicationMissedId}'.padRight(5, '0'));
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: medicationChannelKey,
        title: 'Missed Medication: ${medication.name}',
        body: 'You missed your ${medication.name} at ${schedule.getFormattedTime()}. Please take it as soon as possible.',
        notificationLayout: NotificationLayout.Default,
        color: Colors.red,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'TAKEN_NOW',
          label: 'TAKEN NOW',
          color: Colors.green,
        ),
        NotificationActionButton(
          key: 'SKIP',
          label: 'SKIP',
          color: Colors.grey,
        ),
      ],
    );
  }
  
  // Send device low battery notification
  static Future<void> sendDeviceLowBatteryNotification(String deviceName, int batteryPercentage) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: deviceLowBatteryId,
        channelKey: deviceChannelKey,
        title: 'Low Battery: $deviceName',
        body: 'Your PillPal device battery is low ($batteryPercentage%). Please charge it soon.',
        notificationLayout: NotificationLayout.Default,
        color: Colors.orange,
        category: NotificationCategory.Alarm,
      ),
    );
  }
  
  // Send device disconnected notification
  static Future<void> sendDeviceDisconnectedNotification(String deviceName) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: deviceDisconnectedId,
        channelKey: deviceChannelKey,
        title: 'Device Disconnected: $deviceName',
        body: 'Your PillPal device has disconnected. Please reconnect it to ensure medication reminders work properly.',
        notificationLayout: NotificationLayout.Default,
        color: Colors.red,
        category: NotificationCategory.Alarm,
      ),
    );
  }
  
  // Cancel all notifications for a medication
  static Future<void> cancelMedicationNotifications(int medicationId) async {
    // We need to compute all possible IDs based on our scheme
    final startId = int.parse('$medicationId'.padRight(5, '0'));
    final endId = startId + 1000; // Assumes fewer than 1000 schedules per medication
    
    for (int id = startId; id < endId; id++) {
      await AwesomeNotifications().cancel(id);
    }
  }
  
  // Handle notification actions
  static Future<void> handleNotificationAction(ReceivedAction receivedAction) async {
    // Implement action handling (will be connected to the medication service)
    // This will be implemented when we create the medication service
  }
  
  // Helper: Get next occurrence of a schedule
  static DateTime _getNextOccurrence(TimeOfDay timeOfDay, int dayOfWeek) {
    final now = DateTime.now();
    final scheduleTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    
    // Current day of week (1-7, Monday is 1)
    int currentDayOfWeek = now.weekday;
    
    // Days to add to get to the target day
    int daysToAdd = dayOfWeek - currentDayOfWeek;
    if (daysToAdd < 0) {
      daysToAdd += 7;
    } else if (daysToAdd == 0) {
      // Same day, check if time has passed
      if (now.isAfter(scheduleTime)) {
        daysToAdd = 7; // Schedule for next week
      }
    }
    
    return scheduleTime.add(Duration(days: daysToAdd));
  }
}