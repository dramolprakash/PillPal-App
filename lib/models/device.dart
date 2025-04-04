enum DeviceStatus {
  disconnected,
  connecting,
  connected,
  error
}

enum BatteryLevel {
  low,
  medium,
  high,
  charging
}

class Device {
  final String id;
  final String name;
  final String macAddress;
  final DeviceStatus status;
  final BatteryLevel batteryLevel;
  final int batteryPercentage;
  final List<DeviceCompartment> compartments;
  final String firmwareVersion;
  final DateTime lastSyncTime;

  Device({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.status,
    required this.batteryLevel,
    required this.batteryPercentage,
    required this.compartments,
    required this.firmwareVersion,
    required this.lastSyncTime,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    List<DeviceCompartment> compartments = [];
    if (json['compartments'] != null) {
      compartments = List<DeviceCompartment>.from(
        json['compartments'].map((compartment) => DeviceCompartment.fromJson(compartment))
      );
    }

    return Device(
      id: json['id'],
      name: json['name'],
      macAddress: json['macAddress'],
      status: DeviceStatus.values.byName(json['status']),
      batteryLevel: BatteryLevel.values.byName(json['batteryLevel']),
      batteryPercentage: json['batteryPercentage'],
      compartments: compartments,
      firmwareVersion: json['firmwareVersion'],
      lastSyncTime: DateTime.parse(json['lastSyncTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'macAddress': macAddress,
      'status': status.name,
      'batteryLevel': batteryLevel.name,
      'batteryPercentage': batteryPercentage,
      'compartments': compartments.map((compartment) => compartment.toJson()).toList(),
      'firmwareVersion': firmwareVersion,
      'lastSyncTime': lastSyncTime.toIso8601String(),
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? macAddress,
    DeviceStatus? status,
    BatteryLevel? batteryLevel,
    int? batteryPercentage,
    List<DeviceCompartment>? compartments,
    String? firmwareVersion,
    DateTime? lastSyncTime,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      compartments: compartments ?? this.compartments,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  bool isConnected() {
    return status == DeviceStatus.connected;
  }

  String getBatteryStatusText() {
    switch (batteryLevel) {
      case BatteryLevel.low:
        return 'Low Battery ($batteryPercentage%)';
      case BatteryLevel.medium:
        return 'Medium Battery ($batteryPercentage%)';
      case BatteryLevel.high:
        return 'High Battery ($batteryPercentage%)';
      case BatteryLevel.charging:
        return 'Charging ($batteryPercentage%)';
      default:
        return 'Unknown Battery Status';
    }
  }
}

class DeviceCompartment {
  final int id;
  final int number;
  final int? medicationId;
  final String? medicationName;
  final int capacity;
  final int remaining;

  DeviceCompartment({
    required this.id,
    required this.number,
    this.medicationId,
    this.medicationName,
    required this.capacity,
    required this.remaining,
  });

  factory DeviceCompartment.fromJson(Map<String, dynamic> json) {
    return DeviceCompartment(
      id: json['id'],
      number: json['number'],
      medicationId: json['medicationId'],
      medicationName: json['medicationName'],
      capacity: json['capacity'],
      remaining: json['remaining'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'capacity': capacity,
      'remaining': remaining,
    };
  }

  bool isEmpty() {
    return medicationId == null;
  }

  double getRemainingPercentage() {
    return capacity > 0 ? (remaining / capacity) * 100 : 0;
  }
}