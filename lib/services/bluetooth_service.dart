import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device.dart';

class BluetoothService with ChangeNotifier {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  Device? _pillPalDevice;
  final String _deviceNamePrefix = 'PillPal';
  
  // UUIDs for the PillPal device
  final String _serviceUuid = '00001234-0000-1000-8000-00805f9b34fb';
  final String _deviceInfoCharUuid = '00001235-0000-1000-8000-00805f9b34fb';
  final String _medicationDataCharUuid = '00001236-0000-1000-8000-00805f9b34fb';
  final String _dispenseCommandCharUuid = '00001237-0000-1000-8000-00805f9b34fb';

  // Getters
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Device? get pillPalDevice => _pillPalDevice;
  
  // Start scanning for Bluetooth devices
  Future<void> startScan() async {
    // Check if Bluetooth is available and turned on
    if (!(await flutterBlue.isAvailable)) {
      throw Exception('Bluetooth not available on this device');
    }
    
    // Check if already scanning
    if (_isScanning) return;
    
    // Clear previous results
    _scanResults = [];
    
    // Start scanning
    _isScanning = true;
    notifyListeners();
    
    // Filter for devices with the PillPal prefix
    flutterBlue.startScan(timeout: const Duration(seconds: 10));
    
    // Listen for scan results
    flutterBlue.scanResults.listen((results) {
      // Filter for devices with our prefix
      _scanResults = results.where((result) => 
        result.device.name.startsWith(_deviceNamePrefix)
      ).toList();
      notifyListeners();
    });
    
    // When scan completes
    flutterBlue.isScanning.listen((scanning) {
      if (!scanning && _isScanning) {
        _isScanning = false;
        notifyListeners();
      }
    });
  }
  
  // Stop scanning
  Future<void> stopScan() async {
    if (_isScanning) {
      await flutterBlue.stopScan();
      _isScanning = false;
      notifyListeners();
    }
  }
  
  // Connect to device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Find our service
      BluetoothService? pillPalService = services.firstWhere(
        (service) => service.uuid.toString() == _serviceUuid,
        orElse: () => throw Exception('PillPal service not found on device'),
      );
      
      // Get device info characteristic
      BluetoothCharacteristic? deviceInfoChar = pillPalService.characteristics.firstWhere(
        (char) => char.uuid.toString() == _deviceInfoCharUuid,
        orElse: () => throw Exception('Device info characteristic not found'),
      );
      
      // Read device info
      List<int> deviceInfoBytes = await deviceInfoChar.read();
      String deviceInfoJson = utf8.decode(deviceInfoBytes);
      Map<String, dynamic> deviceInfo = json.decode(deviceInfoJson);
      
      // Create device object
      _pillPalDevice = Device.fromJson(deviceInfo);
      
      notifyListeners();
    } catch (e) {
      _connectedDevice = null;
      _pillPalDevice = null;
      notifyListeners();
      rethrow;
    }
  }
  
  // Disconnect from device
  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _pillPalDevice = null;
      notifyListeners();
    }
  }
  
  // Get medication data from device
  Future<List<DeviceCompartment>> getMedicationData() async {
    if (_connectedDevice == null) {
      throw Exception('No device connected');
    }
    
    try {
      // Discover services
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      // Find our service
      BluetoothService? pillPalService = services.firstWhere(
        (service) => service.uuid.toString() == _serviceUuid,
        orElse: () => throw Exception('PillPal service not found on device'),
      );
      
      // Get medication data characteristic
      BluetoothCharacteristic? medicationDataChar = pillPalService.characteristics.firstWhere(
        (char) => char.uuid.toString() == _medicationDataCharUuid,
        orElse: () => throw Exception('Medication data characteristic not found'),
      );
      
      // Read medication data
      List<int> medicationDataBytes = await medicationDataChar.read();
      String medicationDataJson = utf8.decode(medicationDataBytes);
      List<dynamic> medicationDataList = json.decode(medicationDataJson);
      
      // Parse compartment data
      List<DeviceCompartment> compartments = medicationDataList
          .map((data) => DeviceCompartment.fromJson(data))
          .toList();
      
      // Update device data
      if (_pillPalDevice != null) {
        _pillPalDevice = _pillPalDevice!.copyWith(
          compartments: compartments,
          lastSyncTime: DateTime.now(),
        );
        notifyListeners();
      }
      
      return compartments;
    } catch (e) {
      rethrow;
    }
  }
  
  // Send dispense command to device
  Future<bool> dispenseCompartment(int compartmentNumber) async {
    if (_connectedDevice == null) {
      throw Exception('No device connected');
    }
    
    try {
      // Discover services
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      // Find our service
      BluetoothService? pillPalService = services.firstWhere(
        (service) => service.uuid.toString() == _serviceUuid,
        orElse: () => throw Exception('PillPal service not found on device'),
      );
      
      // Get dispense command characteristic
      BluetoothCharacteristic? dispenseCommandChar = pillPalService.characteristics.firstWhere(
        (char) => char.uuid.toString() == _dispenseCommandCharUuid,
        orElse: () => throw Exception('Dispense command characteristic not found'),
      );
      
      // Send command
      Map<String, dynamic> command = {
        'action': 'dispense',
        'compartment': compartmentNumber,
      };
      
      String commandJson = json.encode(command);
      await dispenseCommandChar.write(utf8.encode(commandJson));
      
      // Update medication data after dispensing
      await getMedicationData();
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  void dispose() {
    disconnectDevice();
    super.dispose();
  }
}