import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/medication_service.dart';
import '../../services/bluetooth_service.dart';
import 'widgets/medication_card.dart';
import 'widgets/device_status_card.dart';
import 'widgets/adherence_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PillPal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data
              final medicationService = context.read<MedicationService>();
              medicationService.loadMedications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildDashboard(),
          _buildScheduleTab(),
          _buildMedicationsTab(),
          _buildDeviceTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Device',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 2 // Show FAB only on Medications tab
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.addMedication);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    return Consumer2<MedicationService, BluetoothService>(
      builder: (context, medicationService, bluetoothService, child) {
        // Get medications due today
        final dueList = medicationService.getMedicationsDue(minutesWindow: 60);
        
        // Get refill alerts
        final refillAlerts = medicationService.getRefillAlerts();
        
        // Get device status
        final device = bluetoothService.pillPalDevice;
        
        // Get adherence stats
        final adherence = medicationService.getAdherenceStats(days: 7);
        
        return RefreshIndicator(
          onRefresh: () async {
            await medicationService.loadMedications();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting section
                Text(
                  'Hello, User!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Today is ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTextColor,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Device status card
                if (device != null)
                  DeviceStatusCard(device: device)
                else
                  _buildConnectDeviceCard(),
                
                const SizedBox(height: 24),
                
                // Upcoming medications section
                Text(
                  'Upcoming Medications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (dueList.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No medications due in the next hour.'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dueList.length,
                    itemBuilder: (context, index) {
                      final medicationDue = dueList[index];
                      return MedicationCard(
                        medication: medicationDue.medication,
                        dueTime: medicationDue.dueTime,
                        minutesUntilDue: medicationDue.minutesUntilDue,
                        onTaken: () {
                          medicationService.logMedicationTaken(
                            medicationDue.medication.id!,
                            medicationDue.dueTime,
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Medication marked as taken'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                  ),
                
                const SizedBox(height: 24),
                
                // Medication adherence chart
                Text(
                  'Weekly Adherence',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                AdherenceChart(adherence: adherence),
                
                const SizedBox(height: 24),
                
                // Refill alerts section
                if (refillAlerts.isNotEmpty) ...[
                  Text(
                    'Refill Alerts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: refillAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = refillAlerts[index];
                      return Card(
                        color: Colors.amber[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Low Supply: ${alert.medication.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Only ${alert.remainingQuantity} ${alert.medication.dosageUnit.name}s left (${alert.remainingPercentage.toStringAsFixed(0)}%)',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Mark as refilled
                                    },
                                    child: const Text('MARK AS REFILLED'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectDeviceCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'No Device Connected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.deviceConnection);
                  },
                  child: const Text('CONNECT'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your PillPal dispenser to enable automatic medication tracking and reminders.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    // For now, we'll navigate to the dedicated schedule screen
    // In a future implementation, we would build the schedule UI directly here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex == 1) {
        Navigator.of(context).pushNamed(AppRoutes.schedule);
      }
    });
    
    return const Center(
      child: Text('Schedule'),
    );
  }

  Widget _buildMedicationsTab() {
    // For now, we'll navigate to the medication list screen
    // In a future implementation, we would build the medication list UI directly here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex == 2) {
        Navigator.of(context).pushNamed(AppRoutes.medicationList);
      }
    });
    
    return const Center(
      child: Text('Medications'),
    );
  }

  Widget _buildDeviceTab() {
    // For now, we'll navigate to the device connection screen
    // In a future implementation, we would build the device UI directly here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex == 3) {
        Navigator.of(context).pushNamed(AppRoutes.deviceConnection);
      }
    });
    
    return const Center(
      child: Text('Device'),
    );
  }
}