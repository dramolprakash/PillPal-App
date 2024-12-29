import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final Logger _logger = Logger();

  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  Future<bool> initialize() async {
    try {
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen(
        (state) {
          if (state == BluetoothAdapterState.on) {
            _logger.i('Bluetooth is ON');
          } else {
            _logger.w('Bluetooth is OFF');
            disconnect();
          }
        },
        onError: (error) {
          _logger.e('Error in adapterState stream', error);
        },
      );
      return true;
    } catch (e) {
      _logger.e('Error initializing Bluetooth', e);
      return false;
    }
  }

  Future<bool> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      return true;
    } catch (e) {
      _logger.e('Error starting scan', e);
      return false;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      _logger.e('Error stopping scan', e);
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      if (_connectedDevice?.id == device.id) {
        _logger.i('Device already connected');
        return true;
      }
      await device.connect();
      _connectedDevice = device;
      return true;
    } catch (e) {
      _logger.e('Error connecting to device', e);
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
      _connectedDevice = null;
    } catch (e) {
      _logger.e('Error disconnecting', e);
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
    try {
      final isAvailable = await FlutterBluePlus.isAvailable;
      final isOn = await FlutterBluePlus.isOn;
      return isAvailable && isOn;
    } catch (e) {
      _logger.e('Error checking Bluetooth availability', e);
      return false;
    }
  }
}
