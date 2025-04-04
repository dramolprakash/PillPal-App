import 'dart:async';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'database_service.dart';
import 'notification_service.dart';

class MedicationService with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Medication> _medications = [];
  Timer? _reminderTimer;
  
  List<Medication> get medications => _medications;
  
  // Initialize the service
  Future<void> init() async {
    await loadMedications();
    _startReminderTimer();
  }
  
  // Load medications from database
  Future<void> loadMedications() async {
    _medications = await _databaseService.getMedications();
    notifyListeners();
  }
  
  // Add a new medication
  Future<Medication> addMedication(Medication medication) async {
    final id = await _databaseService.insertMedication(medication);
    final newMedication = medication.copyWith(id: id);
    
    // Schedule notifications for each schedule
    for (var schedule in newMedication.schedules) {
      await NotificationService.scheduleMedicationReminder(newMedication, schedule);
    }
    
    _medications.add(newMedication);
    notifyListeners();
    return newMedication;
  }
  
  // Update an existing medication
  Future<void> updateMedication(Medication medication) async {
    await _databaseService.updateMedication(medication);
    
    // Cancel old notifications
    await NotificationService.cancelMedicationNotifications(medication.id!);
    
    // Schedule new notifications
    for (var schedule in medication.schedules) {
      await NotificationService.scheduleMedicationReminder(medication, schedule);
    }
    
    // Update the list
    final index = _medications.indexWhere((med) => med.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
      notifyListeners();
    }
  }
  
  // Delete a medication
  Future<void> deleteMedication(int id) async {
    await _databaseService.deleteMedication(id);
    
    // Cancel notifications
    await NotificationService.cancelMedicationNotifications(id);
    
    _medications.removeWhere((med) => med.id == id);
    notifyListeners();
  }
  
  // Log medication taken
  Future<void> logMedicationTaken(int medicationId, DateTime scheduledTime, {String? notes}) async {
    final now = DateTime.now();
    
    final log = MedicationLog(
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      takenTime: now,
      taken: true,
      notes: notes,
    );
    
    await _databaseService.logMedicationTaken(log);
    
    // Update medication remaining quantity
    final medIndex = _medications.indexWhere((med) => med.id == medicationId);
    if (medIndex != -1) {
      final medication = _medications[medIndex];
      final newRemaining = medication.remainingQuantity - 1;
      
      // Update medication
      final updatedMedication = medication.copyWith(
        remainingQuantity: newRemaining >= 0 ? newRemaining : 0,
        logs: [...medication.logs, log],
      );
      
      // Save to database
      await _databaseService.updateMedicationQuantity(
        medicationId, 
        updatedMedication.remainingQuantity,
      );
      
      // Update in memory
      _medications[medIndex] = updatedMedication;
      notifyListeners();
    }
  }
  
  // Log medication missed
  Future<void> logMedicationMissed(int medicationId, DateTime scheduledTime, {String? notes}) async {
    final log = MedicationLog(
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      taken: false,
      notes: notes,
    );
    
    await _databaseService.logMedicationTaken(log);
    
    // Update medication in memory
    final medIndex = _medications.indexWhere((med) => med.id == medicationId);
    if (medIndex != -1) {
      final medication = _medications[medIndex];
      
      // Update medication with new log
      final updatedMedication = medication.copyWith(
        logs: [...medication.logs, log],
      );
      
      // Update in memory
      _medications[medIndex] = updatedMedication;
      notifyListeners();
    }
  }
  
  // Get medications due now or soon
  List<MedicationDue> getMedicationsDue({int minutesWindow = 15}) {
    final now = DateTime.now();
    final List<MedicationDue> dueList = [];
    
    for (var medication in _medications) {
      for (var schedule in medication.schedules) {
        // Check if today is in the days of week
        if (!schedule.daysOfWeek.contains(now.weekday)) continue;
        
        // Create a datetime for the scheduled time today
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          schedule.timeOfDay.hour,
          schedule.timeOfDay.minute,
        );
        
        // Calculate time difference
        final difference = scheduledTime.difference(now).inMinutes;
        
        // If it's due within our window or up to 60 minutes late
        if (difference >= -60 && difference <= minutesWindow) {
          // Check if it's already been logged
          bool alreadyTaken = medication.logs.any((log) => 
            log.scheduledTime.year == scheduledTime.year &&
            log.scheduledTime.month == scheduledTime.month &&
            log.scheduledTime.day == scheduledTime.day &&
            log.scheduledTime.hour == scheduledTime.hour &&
            log.scheduledTime.minute == scheduledTime.minute &&
            log.taken
          );
          
          if (!alreadyTaken) {
            dueList.add(MedicationDue(
              medication: medication,
              schedule: schedule,
              dueTime: scheduledTime,
              minutesUntilDue: difference,
            ));
          }
        }
      }
    }
    
    // Sort by closest due time
    dueList.sort((a, b) => a.minutesUntilDue.compareTo(b.minutesUntilDue));
    
    return dueList;
  }
  
  // Get refill alerts (medications running low)
  List<RefillAlert> getRefillAlerts({double threshold = 0.2}) {
    final List<RefillAlert> alerts = [];
    
    for (var medication in _medications) {
      final remaining = medication.remainingQuantity;
      final total = medication.totalQuantity;
      
      // Check if below threshold
      if (remaining <= total * threshold) {
        alerts.add(RefillAlert(
          medication: medication,
          remainingQuantity: remaining,
          remainingPercentage: (remaining / total) * 100,
        ));
      }
    }
    
    // Sort by lowest percentage first
    alerts.sort((a, b) => a.remainingPercentage.compareTo(b.remainingPercentage));
    
    return alerts;
  }
  
  // Get medication adherence statistics
  MedicationAdherence getAdherenceStats({int days = 30}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    int totalScheduled = 0;
    int totalTaken = 0;
    
    // Build a map of medication adherence by day
    final Map<DateTime, DailyAdherence> dailyMap = {};
    
    // For each medication
    for (var medication in _medications) {
      // Skip medications started after our window
      if (medication.startDate.isAfter(now)) continue;
      
      // Calculate start date for this medication (later of our window or medication start)
      final medStartDate = medication.startDate.isAfter(startDate) 
        ? medication.startDate 
        : startDate;
      
      // For each day in our window
      DateTime currentDate = DateTime(medStartDate.year, medStartDate.month, medStartDate.day);
      while (currentDate.isBefore(now) || _isSameDay(currentDate, now)) {
        // Get day key for the map (date with time zeroed out)
        final dayKey = DateTime(currentDate.year, currentDate.month, currentDate.day);
        
        // Initialize daily adherence object if needed
        if (!dailyMap.containsKey(dayKey)) {
          dailyMap[dayKey] = DailyAdherence(
            date: dayKey,
            scheduled: 0,
            taken: 0,
          );
        }
        
        // For each schedule
        for (var schedule in medication.schedules) {
          // Check if this day matches the schedule
          if (schedule.daysOfWeek.contains(currentDate.weekday)) {
            // Create a datetime for this schedule on this day
            final scheduledTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              schedule.timeOfDay.hour,
              schedule.timeOfDay.minute,
            );
            
            // Don't count future schedules
            if (scheduledTime.isAfter(now)) continue;
            
            totalScheduled++;
            dailyMap[dayKey]!.scheduled++;
            
            // Check if this was taken (by checking logs)
            bool taken = medication.logs.any((log) => 
              _isSameDay(log.scheduledTime, scheduledTime) &&
              log.taken
            );
            
            if (taken) {
              totalTaken++;
              dailyMap[dayKey]!.taken++;
            }
          }
        }
        
        // Move to next day
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
    
    // Calculate rates
    final double overallRate = totalScheduled > 0 ? (totalTaken / totalScheduled) * 100 : 0;
    
    // Convert daily map to list and sort by date
    final dailyList = dailyMap.values.toList();
    dailyList.sort((a, b) => a.date.compareTo(b.date));
    
    return MedicationAdherence(
      startDate: startDate,
      endDate: now,
      totalScheduled: totalScheduled,
      totalTaken: totalTaken,
      adherenceRate: overallRate,
      dailyAdherence: dailyList,
    );
  }
  
  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // Start a timer to check for upcoming medications
  void _startReminderTimer() {
    // Cancel existing timer if any
    _reminderTimer?.cancel();
    
    // Run every minute
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForDueMedications();
    });
  }
  
  // Check for medications due soon
  void _checkForDueMedications() {
    final dueList = getMedicationsDue(minutesWindow: 5);
    
    // Process due medications
    for (var due in dueList) {
      // If it's exactly due now (0 minutes), send notification
      if (due.minutesUntilDue <= 0) {
        NotificationService.scheduleMedicationReminder(due.medication, due.schedule);
      }
      
      // If it's 30 minutes overdue and still not taken, send missed notification
      if (due.minutesUntilDue <= -30) {
        NotificationService.sendMissedMedicationNotification(due.medication, due.schedule);
      }
    }
  }
  
  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }
}

// Helper classes

class MedicationDue {
  final Medication medication;
  final Schedule schedule;
  final DateTime dueTime;
  final int minutesUntilDue;
  
  MedicationDue({
    required this.medication,
    required this.schedule,
    required this.dueTime,
    required this.minutesUntilDue,
  });
}

class RefillAlert {
  final Medication medication;
  final int remainingQuantity;
  final double remainingPercentage;
  
  RefillAlert({
    required this.medication,
    required this.remainingQuantity,
    required this.remainingPercentage,
  });
}

class MedicationAdherence {
  final DateTime startDate;
  final DateTime endDate;
  final int totalScheduled;
  final int totalTaken;
  final double adherenceRate;
  final List<DailyAdherence> dailyAdherence;
  
  MedicationAdherence({
    required this.startDate,
    required this.endDate,
    required this.totalScheduled,
    required this.totalTaken,
    required this.adherenceRate,
    required this.dailyAdherence,
  });
}

class DailyAdherence {
  final DateTime date;
  int scheduled;
  int taken;
  
  DailyAdherence({
    required this.date,
    required this.scheduled,
    required this.taken,
  });
  
  double get rate => scheduled > 0 ? (taken / scheduled) * 100 : 0;
}