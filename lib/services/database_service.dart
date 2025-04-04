import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/medication.dart';
import '../models/device.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  
  factory DatabaseService() => _instance;
  
  DatabaseService._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pill_pal.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE user(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL
      )
    ''');
    
    // Emergency contacts table
    await db.execute('''
      CREATE TABLE emergency_contact(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        relationship TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');
    
    // Medications table
    await db.execute('''
      CREATE TABLE medication(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage REAL NOT NULL,
        dosage_unit TEXT NOT NULL,
        instructions TEXT NOT NULL,
        frequency INTEGER NOT NULL,
        total_quantity INTEGER NOT NULL,
        remaining_quantity INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        photo_url TEXT
      )
    ''');
    
    // Schedules table
    await db.execute('''
      CREATE TABLE schedule(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        time_of_day TEXT NOT NULL,
        days_of_week TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medication (id) ON DELETE CASCADE
      )
    ''');
    
    // Medication logs table
    await db.execute('''
      CREATE TABLE medication_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        scheduled_time TEXT NOT NULL,
        taken_time TEXT,
        taken INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (medication_id) REFERENCES medication (id) ON DELETE CASCADE
      )
    ''');
    
    // Device table
    await db.execute('''
      CREATE TABLE device(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mac_address TEXT NOT NULL,
        status TEXT NOT NULL,
        battery_level TEXT NOT NULL,
        battery_percentage INTEGER NOT NULL,
        firmware_version TEXT NOT NULL,
        last_sync_time TEXT NOT NULL
      )
    ''');
    
    // Device compartments table
    await db.execute('''
      CREATE TABLE device_compartment(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        number INTEGER NOT NULL,
        medication_id INTEGER,
        capacity INTEGER NOT NULL,
        remaining INTEGER NOT NULL,
        FOREIGN KEY (device_id) REFERENCES device (id) ON DELETE CASCADE,
        FOREIGN KEY (medication_id) REFERENCES medication (id) ON DELETE SET NULL
      )
    ''');
  }
  
  // User methods
  Future<int> insertUser(User user) async {
    final db = await database;
    final userId = await db.insert('user', {
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
    });
    
    // Insert emergency contacts
    for (var contact in user.emergencyContacts) {
      await db.insert('emergency_contact', {
        'user_id': userId,
        'name': contact.name,
        'phone': contact.phone,
        'relationship': contact.relationship,
      });
    }
    
    return userId;
  }
  
  Future<User?> getUser() async {
    final db = await database;
    final users = await db.query('user');
    
    if (users.isEmpty) return null;
    
    final userData = users.first;
    final userId = userData['id'] as int;
    
    // Get emergency contacts
    final contactsData = await db.query(
      'emergency_contact',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    final contacts = contactsData.map((contact) => EmergencyContact(
      id: contact['id'] as int,
      name: contact['name'] as String,
      phone: contact['phone'] as String,
      relationship: contact['relationship'] as String,
    )).toList();
    
    return User(
      id: userId,
      name: userData['name'] as String,
      email: userData['email'] as String,
      phone: userData['phone'] as String,
      emergencyContacts: contacts,
    );
  }
  
  Future<void> updateUser(User user) async {
    final db = await database;
    
    await db.update(
      'user',
      {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
    
    // Handle emergency contacts
    // First delete all existing contacts
    await db.delete(
      'emergency_contact',
      where: 'user_id = ?',
      whereArgs: [user.id],
    );
    
    // Then insert new ones
    for (var contact in user.emergencyContacts) {
      await db.insert('emergency_contact', {
        'user_id': user.id,
        'name': contact.name,
        'phone': contact.phone,
        'relationship': contact.relationship,
      });
    }
  }
  
  // Medication methods
  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    
    // Insert medication
    final medicationId = await db.insert('medication', {
      'name': medication.name,
      'dosage': medication.dosage,
      'dosage_unit': medication.dosageUnit.name,
      'instructions': medication.instructions,
      'frequency': medication.frequency,
      'total_quantity': medication.totalQuantity,
      'remaining_quantity': medication.remainingQuantity,
      'start_date': medication.startDate.toIso8601String(),
      'end_date': medication.endDate?.toIso8601String(),
      'photo_url': medication.photoUrl,
    });
    
    // Insert schedules
    for (var schedule in medication.schedules) {
      final timeString = '${schedule.timeOfDay.hour.toString().padLeft(2, '0')}:${schedule.timeOfDay.minute.toString().padLeft(2, '0')}';
      final daysString = schedule.daysOfWeek.join(',');
      
      await db.insert('schedule', {
        'medication_id': medicationId,
        'time_of_day': timeString,
        'days_of_week': daysString,
      });
    }
    
    return medicationId;
  }
  
  Future<List<Medication>> getMedications() async {
    final db = await database;
    final medicationsData = await db.query('medication');
    
    if (medicationsData.isEmpty) return [];
    
    final medications = <Medication>[];
    
    for (var medData in medicationsData) {
      final medicationId = medData['id'] as int;
      
      // Get schedules
      final schedulesData = await db.query(
        'schedule',
        where: 'medication_id = ?',
        whereArgs: [medicationId],
      );
      
      final schedules = schedulesData.map((scheduleData) {
        final timeString = scheduleData['time_of_day'] as String;
        final daysString = scheduleData['days_of_week'] as String;
        
        final timeParts = timeString.split(':');
        final timeOfDay = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
        
        final daysOfWeek = daysString.split(',').map(int.parse).toList();
        
        return Schedule(
          id: scheduleData['id'] as int,
          timeOfDay: timeOfDay,
          daysOfWeek: daysOfWeek,
        );
      }).toList();
      
      // Get logs
      final logsData = await db.query(
        'medication_log',
        where: 'medication_id = ?',
        whereArgs: [medicationId],
      );
      
      final logs = logsData.map((logData) {
        return MedicationLog(
          id: logData['id'] as int,
          medicationId: medicationId,
          scheduledTime: DateTime.parse(logData['scheduled_time'] as String),
          takenTime: logData['taken_time'] != null ? DateTime.parse(logData['taken_time'] as String) : null,
          taken: logData['taken'] == 1,
          notes: logData['notes'] as String?,
        );
      }).toList();
      
      medications.add(Medication(
        id: medicationId,
        name: medData['name'] as String,
        dosage: medData['dosage'] as double,
        dosageUnit: DosageUnit.values.byName(medData['dosage_unit'] as String),
        instructions: medData['instructions'] as String,
        frequency: medData['frequency'] as int,
        totalQuantity: medData['total_quantity'] as int,
        remainingQuantity: medData['remaining_quantity'] as int,
        startDate: DateTime.parse(medData['start_date'] as String),
        endDate: medData['end_date'] != null ? DateTime.parse(medData['end_date'] as String) : null,
        schedules: schedules,
        photoUrl: medData['photo_url'] as String?,
        logs: logs,
      ));
    }
    
    return medications;
  }
  
  Future<Medication?> getMedication(int id) async {
    final db = await database;
    final medData = await db.query(
      'medication',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (medData.isEmpty) return null;
    
    // Get schedules
    final schedulesData = await db.query(
      'schedule',
      where: 'medication_id = ?',
      whereArgs: [id],
    );
    
    final schedules = schedulesData.map((scheduleData) {
      final timeString = scheduleData['time_of_day'] as String;
      final daysString = scheduleData['days_of_week'] as String;
      
      final timeParts = timeString.split(':');
      final timeOfDay = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      
      final daysOfWeek = daysString.split(',').map(int.parse).toList();
      
      return Schedule(
        id: scheduleData['id'] as int,
        timeOfDay: timeOfDay,
        daysOfWeek: daysOfWeek,
      );
    }).toList();
    
    // Get logs
    final logsData = await db.query(
      'medication_log',
      where: 'medication_id = ?',
      whereArgs: [id],
    );
    
    final logs = logsData.map((logData) {
      return MedicationLog(
        id: logData['id'] as int,
        medicationId: id,
        scheduledTime: DateTime.parse(logData['scheduled_time'] as String),
        takenTime: logData['taken_time'] != null ? DateTime.parse(logData['taken_time'] as String) : null,
        taken: logData['taken'] == 1,
        notes: logData['notes'] as String?,
      );
    }).toList();
    
    final data = medData.first;
    return Medication(
      id: id,
      name: data['name'] as String,
      dosage: data['dosage'] as double,
      dosageUnit: DosageUnit.values.byName(data['dosage_unit'] as String),
      instructions: data['instructions'] as String,
      frequency: data['frequency'] as int,
      totalQuantity: data['total_quantity'] as int,
      remainingQuantity: data['remaining_quantity'] as int,
      startDate: DateTime.parse(data['start_date'] as String),
      endDate: data['end_date'] != null ? DateTime.parse(data['end_date'] as String) : null,
      schedules: schedules,
      photoUrl: data['photo_url'] as String?,
      logs: logs,
    );
  }
  
  Future<void> updateMedication(Medication medication) async {
    final db = await database;
    
    await db.update(
      'medication',
      {
        'name': medication.name,
        'dosage': medication.dosage,
        'dosage_unit': medication.dosageUnit.name,
        'instructions': medication.instructions,
        'frequency': medication.frequency,
        'total_quantity': medication.totalQuantity,
        'remaining_quantity': medication.remainingQuantity,
        'start_date': medication.startDate.toIso8601String(),
        'end_date': medication.endDate?.toIso8601String(),
        'photo_url': medication.photoUrl,
      },
      where: 'id = ?',
      whereArgs: [medication.id],
    );
    
    // Handle schedules
    // First delete all existing schedules
    await db.delete(
      'schedule',
      where: 'medication_id = ?',
      whereArgs: [medication.id],
    );
    
    // Then insert new ones
    for (var schedule in medication.schedules) {
      final timeString = '${schedule.timeOfDay.hour.toString().padLeft(2, '0')}:${schedule.timeOfDay.minute.toString().padLeft(2, '0')}';
      final daysString = schedule.daysOfWeek.join(',');
      
      await db.insert('schedule', {
        'medication_id': medication.id,
        'time_of_day': timeString,
        'days_of_week': daysString,
      });
    }
  }
  
  Future<void> deleteMedication(int id) async {
    final db = await database;
    
    await db.delete(
      'medication',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> updateMedicationQuantity(int id, int remaining) async {
    final db = await database;
    
    await db.update(
      'medication',
      {'remaining_quantity': remaining},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> logMedicationTaken(MedicationLog log) async {
    final db = await database;
    
    return await db.insert('medication_log', {
      'medication_id': log.medicationId,
      'scheduled_time': log.scheduledTime.toIso8601String(),
      'taken_time': log.takenTime?.toIso8601String(),
      'taken': log.taken ? 1 : 0,
      'notes': log.notes,
    });
  }
  
  // Device methods
  Future<void> saveDevice(Device device) async {
    final db = await database;
    
    // First, check if device exists
    final existingDevice = await db.query(
      'device',
      where: 'id = ?',
      whereArgs: [device.id],
    );
    
    if (existingDevice.isEmpty) {
      // Insert new device
      await db.insert('device', {
        'id': device.id,
        'name': device.name,
        'mac_address': device.macAddress,
        'status': device.status.name,
        'battery_level': device.batteryLevel.name,
        'battery_percentage': device.batteryPercentage,
        'firmware_version': device.firmwareVersion,
        'last_sync_time': device.lastSyncTime.toIso8601String(),
      });
    } else {
      // Update existing device
      await db.update(
        'device',
        {
          'name': device.name,
          'mac_address': device.macAddress,
          'status': device.status.name,
          'battery_level': device.batteryLevel.name,
          'battery_percentage': device.batteryPercentage,
          'firmware_version': device.firmwareVersion,
          'last_sync_time': device.lastSyncTime.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [device.id],
      );
    }
    
    // Handle compartments
    // First delete all existing compartments
    await db.delete(
      'device_compartment',
      where: 'device_id = ?',
      whereArgs: [device.id],
    );
    
    // Then insert new ones
    for (var compartment in device.compartments) {
      await db.insert('device_compartment', {
        'device_id': device.id,
        'number': compartment.number,
        'medication_id': compartment.medicationId,
        'capacity': compartment.capacity,
        'remaining': compartment.remaining,
      });
    }
  }
  
  Future<Device?> getLastConnectedDevice() async {
    final db = await database;
    final devicesData = await db.query('device');
    
    if (devicesData.isEmpty) return null;
    
    // Sort by last sync time and get the most recent
    devicesData.sort((a, b) {
      final aTime = DateTime.parse(a['last_sync_time'] as String);
      final bTime = DateTime.parse(b['last_sync_time'] as String);
      return bTime.compareTo(aTime);
    });
    
    final deviceData = devicesData.first;
    final deviceId = deviceData['id'] as String;
    
    // Get compartments
    final compartmentsData = await db.query(
      'device_compartment',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    
    final compartments = compartmentsData.map((compData) {
      return DeviceCompartment(
        id: compData['id'] as int,
        number: compData['number'] as int,
        medicationId: compData['medication_id'] as int?,
        capacity: compData['capacity'] as int,
        remaining: compData['remaining'] as int,
      );
    }).toList();
    
    return Device(
      id: deviceId,
      name: deviceData['name'] as String,
      macAddress: deviceData['mac_address'] as String,
      status: DeviceStatus.values.byName(deviceData['status'] as String),
      batteryLevel: BatteryLevel.values.byName(deviceData['battery_level'] as String),
      batteryPercentage: deviceData['battery_percentage'] as int,
      compartments: compartments,
      firmwareVersion: deviceData['firmware_version'] as String,
      lastSyncTime: DateTime.parse(deviceData['last_sync_time'] as String),
    );
  }
  
  // Clean up and close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}