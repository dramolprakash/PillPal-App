import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final TimeOfDay time;
  final int compartment;
  final int remainingDoses;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.compartment,
    required this.remainingDoses,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      time: TimeOfDay(
        hour: json['hour'],
        minute: json['minute'],
      ),
      compartment: json['compartment'],
      remainingDoses: json['remainingDoses'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'hour': time.hour,
      'minute': time.minute,
      'compartment': compartment,
      'remainingDoses': remainingDoses,
    };
  }
}
