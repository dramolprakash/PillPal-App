import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  Future<bool> initialize() async {
    try {
      _adapterStateSubscription = flutterBlue.adapterState.listen(
        (state) {
          if (state == BluetoothAdapterState.on) {
            print('Bluetooth is ON');
          } else {
            print('Bluetooth is OFF');
            disconnect();
          }
        },
        onError: (error) {
          print('Error in adapterState stream: $error');
        },
      );
      return true;
    } catch (e) {
      print('Error initializing Bluetooth: $e');
      return false;
    }
  }

  Future<bool> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      await flutterBlue.startScan(timeout: timeout);
      return true;
    } catch (e) {
      print('Error starting scan: $e');
      return false;
    }
  }

  Future<void> stopScan() async {
    try {
      await flutterBlue.stopScan();
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      if (_connectedDevice?.id == device.id) {
        print('Device already connected');
        return true;
      }
      await device.connect();
      _connectedDevice = device;
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
      _connectedDevice = null;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  Future<void> dispose() async {
    await _adapterStateSubscription?.cancel();
    await stopScan();
    await disconnect();
  }

  bool get isConnected => _connectedDevice != null;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<bool> isBluetoothAvailable() async {
    final isAvailable = await flutterBlue.isAvailable;
    final isOn = await flutterBlue.isOn;
    return isAvailable && isOn;
  }
}
