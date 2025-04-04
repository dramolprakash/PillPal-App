import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/bluetooth_service.dart';
import '../../models/device.dart';
import '../../services/medication_service.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  bool _isLoading = false;
  TextEditingController _deviceNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initDeviceData();
  }
  
  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }
  
  Future<void> _initDeviceData() async {
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    final device = bluetoothService.pillPalDevice;
    
    if (device != null) {
      setState(() {
        _deviceNameController.text = device.name;
      });
    }
  }
  
  Future<void> _refreshDeviceData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
      await bluetoothService.getMedicationData();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing device data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _disconnectDevice() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
      await bluetoothService.disconnectDevice();
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disconnecting device: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showDisconnectConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disconnect Device'),
          content: const Text(
            'Are you sure you want to disconnect from this device? ' +
            'You will need to reconnect to receive medication alerts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _disconnectDevice();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('DISCONNECT'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _configureCompartment(DeviceCompartment compartment) async {
    final medicationService = Provider.of<MedicationService>(context, listen: false);
    final medications = medicationService.medications;
    
    // Show dialog to select medication for this compartment
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        Medication? selectedMedication;
        
        if (compartment.medicationId != null) {
          selectedMedication = medications.firstWhere(
            (med) => med.id == compartment.medicationId,
            orElse: () => null as Medication,
          );
        }
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Configure Compartment ${compartment.number}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select medication for this compartment:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Medication?>(
                    value: selectedMedication,
                    decoration: const InputDecoration(
                      labelText: 'Medication',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<Medication?>(
                        value: null,
                        child: Text('None (Empty)'),
                      ),
                      ...medications.map((medication) {
                        return DropdownMenuItem<Medication?>(
                          value: medication,
                          child: Text(medication.name),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedMedication = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'medicationId': selectedMedication?.id,
                      'medicationName': selectedMedication?.name,
                    });
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (result != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // This would normally update the device compartment via Bluetooth
        // For now, we're just updating the local device data
        final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
        final device = bluetoothService.pillPalDevice;
        
        if (device != null) {
          final compartments = List<DeviceCompartment>.from(device.compartments);
          final index = compartments.indexWhere((c) => c.id == compartment.id);
          
          if (index != -1) {
            compartments[index] = DeviceCompartment(
              id: compartment.id,
              number: compartment.number,
              medicationId: result['medicationId'],
              medicationName: result['medicationName'],
              capacity: compartment.capacity,
              remaining: compartment.remaining,
            );
            
            // In a real implementation, this would send the updated configuration to the device
            // and then fetch the updated device data
            // For now, we'll just update the local state
            final updatedDevice = device.copyWith(
              compartments: compartments,
              lastSyncTime: DateTime.now(),
            );
            
            // Normally we would save this to the database
          }
        }
        
        // Refresh device data
        await _refreshDeviceData();
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error configuring compartment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _dispenseCompartment(DeviceCompartment compartment) async {
    if (compartment.isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compartment is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Dispense from Compartment ${compartment.number}'),
          content: Text(
            'Are you sure you want to dispense ${compartment.medicationName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DISPENSE'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
        final result = await bluetoothService.dispenseCompartment(compartment.number);
        
        if (!mounted) return;
        
        if (result) {
          // If dispensed successfully
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication dispensed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // If medication was logged automatically, we would need to update the UI
          // For now, we just refresh the device data
          await _refreshDeviceData();
        } else {
          // If dispense failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to dispense medication'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error dispensing medication: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDeviceData,
          ),
        ],
      ),
      body: Consumer<BluetoothService>(
        builder: (context, bluetoothService, child) {
          final device = bluetoothService.pillPalDevice;
          
          if (device == null) {
            return const Center(
              child: Text('No device connected'),
            );
          }
          
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refreshDeviceData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device info card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Device Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Device name
                              _buildInfoRow(
                                icon: Icons.device_unknown,
                                title: 'Name',
                                value: device.name,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // MAC address
                              _buildInfoRow(
                                icon: Icons.perm_device_info,
                                title: 'MAC Address',
                                value: device.macAddress,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Firmware version
                              _buildInfoRow(
                                icon: Icons.system_update,
                                title: 'Firmware',
                                value: device.firmwareVersion,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Battery info
                              _buildInfoRow(
                                icon: _getBatteryIcon(device.batteryLevel),
                                title: 'Battery',
                                value: device.getBatteryStatusText(),
                                valueColor: _getBatteryColor(device.batteryLevel),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Last sync
                              _buildInfoRow(
                                icon: Icons.sync,
                                title: 'Last Sync',
                                value: DateFormat('MMM d, h:mm a').format(device.lastSyncTime),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Compartments section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Compartments',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _refreshDeviceData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('REFRESH'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Compartment list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: device.compartments.length,
                        itemBuilder: (context, index) {
                          final compartment = device.compartments[index];
                          return _buildCompartmentItem(compartment);
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Disconnect button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showDisconnectConfirmDialog,
                          icon: const Icon(Icons.bluetooth_disabled),
                          label: const Text('DISCONNECT DEVICE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  // Helper to build info row
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.lightTextColor,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper to build compartment item
  Widget _buildCompartmentItem(DeviceCompartment compartment) {
    final isEmpty = compartment.isEmpty();
    final isLow = compartment.getRemainingPercentage() < 20;
    
    Color statusColor;
    String statusText;
    
    if (isEmpty) {
      statusColor = Colors.grey;
      statusText = 'Empty';
    } else if (isLow) {
      statusColor = Colors.orange;
      statusText = 'Low';
    } else {
      statusColor = Colors.green;
      statusText = 'Ok';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Compartment number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${compartment.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Medication name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEmpty ? 'Empty Compartment' : compartment.medicationName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isEmpty)
                            Text(
                              '${compartment.remaining}/${compartment.capacity}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.lightTextColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'Configure',
                      onPressed: () => _configureCompartment(compartment),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      tooltip: 'Dispense',
                      onPressed: isEmpty ? null : () => _dispenseCompartment(compartment),
                      color: isEmpty ? Colors.grey : Colors.green,
                    ),
                  ],
                ),
              ],
            ),
            
            // Progress bar
            if (!isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: compartment.remaining / compartment.capacity,
                    backgroundColor: Colors.grey.shade200,
                    color: statusColor,
                    minHeight: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Helper to get battery icon
  IconData _getBatteryIcon(BatteryLevel level) {
    switch (level) {
      case BatteryLevel.low:
        return Icons.battery_alert;
      case BatteryLevel.medium:
        return Icons.battery_3_bar;
      case BatteryLevel.high:
        return Icons.battery_full;
      case BatteryLevel.charging:
        return Icons.battery_charging_full;
    }
  }
  
  // Helper to get battery color
  Color _getBatteryColor(BatteryLevel level) {
    switch (level) {
      case BatteryLevel.low:
        return Colors.red;
      case BatteryLevel.medium:
        return Colors.orange;
      case BatteryLevel.high:
        return Colors.green;
      case BatteryLevel.charging:
        return Colors.green;
    }
  }
}