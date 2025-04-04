// ignore_for_file: unused_local_variable

import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; // Import for Flutter's TimeOfDay

enum DosageUnit { mg, ml, tablet, capsule, unit }

class Medication {
  final int? id;
  final String name;
  final double dosage;
  final DosageUnit dosageUnit;
  final String instructions;
  final int frequency;
  final int totalQuantity;
  final int remainingQuantity;
  final DateTime startDate;
  final DateTime? endDate;
  final List<Schedule> schedules;
  final String? photoUrl;
  final List<MedicationLog> logs;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.dosageUnit,
    required this.instructions,
    required this.frequency,
    required this.totalQuantity,
    required this.remainingQuantity,
    required this.startDate,
    this.endDate,
    required this.schedules,
    this.photoUrl,
    this.logs = const [],
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    List<Schedule> schedules = [];
    if (json['schedules'] != null) {
      schedules = List<Schedule>.from(
        json['schedules'].map((schedule) => Schedule.fromJson(schedule))
      );
    }

    List<MedicationLog> logs = [];
    if (json['logs'] != null) {
      logs = List<MedicationLog>.from(
        json['logs'].map((log) => MedicationLog.fromJson(log))
      );
    }

    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      dosageUnit: DosageUnit.values.byName(json['dosageUnit']),
      instructions: json['instructions'],
      frequency: json['frequency'],
      totalQuantity: json['totalQuantity'],
      remainingQuantity: json['remainingQuantity'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      schedules: schedules,
      photoUrl: json['photoUrl'],
      logs: logs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'dosageUnit': dosageUnit.name,
      'instructions': instructions,
      'frequency': frequency,
      'totalQuantity': totalQuantity,
      'remainingQuantity': remainingQuantity,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'schedules': schedules.map((schedule) => schedule.toJson()).toList(),
      'photoUrl': photoUrl,
      'logs': logs.map((log) => log.toJson()).toList(),
    };
  }

  Medication copyWith({
    int? id,
    String? name,
    double? dosage,
    DosageUnit? dosageUnit,
    String? instructions,
    int? frequency,
    int? totalQuantity,
    int? remainingQuantity,
    DateTime? startDate,
    DateTime? endDate,
    List<Schedule>? schedules,
    String? photoUrl,
    List<MedicationLog>? logs,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      instructions: instructions ?? this.instructions,
      frequency: frequency ?? this.frequency,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      schedules: schedules ?? this.schedules,
      photoUrl: photoUrl ?? this.photoUrl,
      logs: logs ?? this.logs,
    );
  }

  double getComplianceRate() {
    if (logs.isEmpty) return 0.0;
    
    int totalScheduled = 0;
    int totalTaken = 0;
    
    // Count from the start date to today
    DateTime now = DateTime.now();
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    
    while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
      for (var schedule in schedules) {
        totalScheduled++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    totalTaken = logs.where((log) => log.taken).length;
    
    return totalScheduled > 0 ? (totalTaken / totalScheduled) * 100 : 0.0;
  }

  String getFormattedDosage() {
    return '$dosage ${dosageUnit.name}';
  }
}

class Schedule {
  final int? id;
  final TimeOfDay timeOfDay;
  final List<int> daysOfWeek; // 1-7, where 1 is Monday

  Schedule({
    this.id,
    required this.timeOfDay,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7], // Default is every day
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    List<String> timeParts = json['timeOfDay'].split(':');
    return Schedule(
      id: json['id'],
      timeOfDay: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      daysOfWeek: List<int>.from(json['daysOfWeek']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeOfDay': '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}',
      'daysOfWeek': daysOfWeek,
    };
  }

  String getFormattedTime() {
    final format = DateFormat('hh:mm a');
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    return format.format(dateTime);
  }
}

class MedicationLog {
  final int? id;
  final int medicationId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool taken;
  final String? notes;

  MedicationLog({
    this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    required this.taken,
    this.notes,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'],
      medicationId: json['medicationId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      takenTime: json['takenTime'] != null ? DateTime.parse(json['takenTime']) : null,
      taken: json['taken'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'taken': taken,
      'notes': notes,
    };
  }
}