import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/device.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';

class DeviceStatusCard extends StatelessWidget {
  final Device device;
  
  const DeviceStatusCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    // Format last sync time
    final dateFormat = DateFormat('MMM d, h:mm a');
    final formattedSyncTime = dateFormat.format(device.lastSyncTime);
    
    // Device status info
    final isConnected = device.status == DeviceStatus.connected;
    final statusColor = isConnected ? Colors.green : Colors.red;
    final statusText = isConnected ? 'Connected' : 'Disconnected';
    
    // Battery status info
    Color batteryColor;
    IconData batteryIcon;
    
    switch (device.batteryLevel) {
      case BatteryLevel.low:
        batteryColor = Colors.red;
        batteryIcon = Icons.battery_alert;
        break;
      case BatteryLevel.medium:
        batteryColor = Colors.orange;
        batteryIcon = Icons.battery_3_bar;
        break;
      case BatteryLevel.high:
        batteryColor = Colors.green;
        batteryIcon = Icons.battery_full;
        break;
      case BatteryLevel.charging:
        batteryColor = Colors.green;
        batteryIcon = Icons.battery_charging_full;
        break;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device title and status
            Row(
              children: [
                const Icon(Icons.devices, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Battery status
            Row(
              children: [
                Icon(batteryIcon, size: 16, color: batteryColor),
                const SizedBox(width: 8),
                Text(
                  device.getBatteryStatusText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: batteryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Last sync time
            Row(
              children: [
                const Icon(Icons.sync, size: 16, color: AppTheme.lightTextColor),
                const SizedBox(width: 8),
                Text(
                  'Last synced: $formattedSyncTime',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Compartment status section
            const Text(
              'Compartment Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Compartment grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: device.compartments.length,
              itemBuilder: (context, index) {
                final compartment = device.compartments[index];
                final isEmpty = compartment.isEmpty();
                final isLow = compartment.getRemainingPercentage() < 20;
                
                Color color;
                if (isEmpty) {
                  color = Colors.grey;
                } else if (isLow) {
                  color = Colors.orange;
                } else {
                  color = Colors.green;
                }
                
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'C${compartment.number}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                      if (!isEmpty)
                        Text(
                          '${compartment.remaining}/${compartment.capacity}',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                          ),
                        ),
                      if (isEmpty)
                        const Text(
                          'Empty',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.deviceSettings);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('SETTINGS'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isConnected
                      ? null // Already connected
                      : () {
                          Navigator.of(context).pushNamed(AppRoutes.deviceConnection);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(isConnected ? 'CONNECTED' : 'RECONNECT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}