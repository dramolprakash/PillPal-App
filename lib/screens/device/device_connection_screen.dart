import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/bluetooth_service.dart';
import '../../models/device.dart';

class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  bool _isScanning = false;
  
  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }
  
  Future<void> _checkBluetoothStatus() async {
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    
    try {
      final isAvailable = await FlutterBluePlus.instance.isAvailable;
      if (!isAvailable && mounted) {
        _showBluetoothNotAvailableDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking Bluetooth: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _startScan() async {
    if (_isScanning) return;
    
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    
    setState(() {
      _isScanning = true;
    });
    
    try {
      await bluetoothService.startScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning for devices: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }
  
  Future<void> _stopScan() async {
    if (!_isScanning) return;
    
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    
    try {
      await bluetoothService.stopScan();
    } catch (e) {
      // Ignore errors when stopping scan
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }
  
  Future<void> _connectToDevice(BluetoothDevice device) async {
    _stopScan();
    
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    
    try {
      // Show connecting dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const AlertDialog(
            title: Text('Connecting'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to device...'),
              ],
            ),
          );
        },
      );
      
      await bluetoothService.connectToDevice(device);
      
      if (!mounted) return;
      Navigator.pop(context); // Close connecting dialog
      
      // Show success and navigate to device settings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device connected successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pushReplacementNamed(context, AppRoutes.deviceSettings);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close connecting dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to device: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showBluetoothNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bluetooth Not Available'),
          content: const Text(
            'Bluetooth is not available on this device or is turned off. ' +
            'Please enable Bluetooth to connect to PillPal device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device'),
      ),
      body: Consumer<BluetoothService>(
        builder: (context, bluetoothService, child) {
          final scanResults = bluetoothService.scanResults;
          final isScanning = bluetoothService.isScanning;
          final connectedDevice = bluetoothService.connectedDevice;
          
          return Column(
            children: [
              // Connected device section
              if (connectedDevice != null) _buildConnectedDeviceSection(connectedDevice),
              
              // Scan button
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isScanning ? _stopScan : _startScan,
                        icon: Icon(isScanning ? Icons.stop : Icons.search),
                        label: Text(isScanning ? 'Stop Scan' : 'Scan for Devices'),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scanning indicator
              if (isScanning)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              
              // Device list
              Expanded(
                child: scanResults.isEmpty
                    ? Center(
                        child: Text(
                          isScanning 
                              ? 'Scanning for devices...' 
                              : 'No devices found. Tap Scan to search for devices.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: scanResults.length,
                        itemBuilder: (context, index) {
                          final result = scanResults[index];
                          return _buildDeviceItem(result);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildConnectedDeviceSection(BluetoothDevice device) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected, color: Colors.green),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected Device',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  device.name.isNotEmpty ? device.name : 'Unknown Device',
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.deviceSettings);
            },
            child: const Text('SETTINGS'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceItem(ScanResult result) {
    final device = result.device;
    final deviceName = device.name.isNotEmpty ? device.name : 'Unknown Device';
    final rssi = result.rssi;
    
    // Signal strength icon
    IconData signalIcon;
    Color signalColor;
    
    if (rssi >= -60) {
      signalIcon = Icons.signal_cellular_4_bar;
      signalColor = Colors.green;
    } else if (rssi >= -70) {
      signalIcon = Icons.signal_cellular_3_bar;
      signalColor = Colors.green;
    } else if (rssi >= -80) {
      signalIcon = Icons.signal_cellular_2_bar;
      signalColor = Colors.orange;
    } else {
      signalIcon = Icons.signal_cellular_1_bar;
      signalColor = Colors.red;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, color: AppTheme.primaryColor),
        title: Text(deviceName),
        subtitle: Text('Signal: $rssi dBm'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(signalIcon, color: signalColor),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _connectToDevice(device),
              child: const Text('CONNECT'),
            ),
          ],
        ),
        onTap: () => _connectToDevice(device),
      ),
    );
  }
}