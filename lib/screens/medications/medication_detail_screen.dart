// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/medication_service.dart';
import '../../models/medication.dart';

class MedicationDetailScreen extends StatefulWidget {
  final int id;
  
  const MedicationDetailScreen({
    super.key,
    required this.id,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Medication? _medication;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedication();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMedication() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      await medicationService.loadMedications();
      
      setState(() {
        _medication = medicationService.medications.firstWhere(
          (med) => med.id == widget.id,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading medication: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteMedication() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Medication'),
          content: const Text(
            'Are you sure you want to delete this medication? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true && _medication != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final medicationService = Provider.of<MedicationService>(context, listen: false);
        await medicationService.deleteMedication(_medication!.id!);
        
        if (!mounted) return;
        Navigator.pop(context); // Return to previous screen
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting medication: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _takeMedication() async {
    if (_medication == null) return;
    
    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      
      // Take medication with current time
      await medicationService.logMedicationTaken(
        _medication!.id!,
        DateTime.now(),
        notes: 'Taken manually from medication details',
      );
      
      // Reload medication data
      await _loadMedication();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication marked as taken'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking medication: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medication Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_medication == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medication Details')),
        body: const Center(child: Text('Medication not found')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_medication!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.addMedication,
                arguments: {'id': _medication!.id},
              ).then((_) => _loadMedication());
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteMedication,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Schedule'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildScheduleTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _takeMedication,
        icon: const Icon(Icons.check),
        label: const Text('TAKE NOW'),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    // Calculate adherence
    final adherenceRate = _medication!.getComplianceRate();
    
    // Determine adherence color
    Color adherenceColor;
    if (adherenceRate >= 80) {
      adherenceColor = Colors.green;
    } else if (adherenceRate >= 50) {
      adherenceColor = Colors.orange;
    } else {
      adherenceColor = Colors.red;
    }
    
    // Remaining quantity percentage
    final remainingPercentage = _medication!.remainingQuantity / _medication!.totalQuantity;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dosage
                  _buildInfoRow(
                    icon: Icons.medical_information,
                    title: 'Dosage',
                    value: '${_medication!.dosage} ${_medication!.dosageUnit.name}',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Frequency
                  _buildInfoRow(
                    icon: Icons.repeat,
                    title: 'Frequency',
                    value: '${_medication!.frequency} time(s) daily',
                  ),
                  
                  if (_medication!.instructions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    
                    // Instructions
                    _buildInfoRow(
                      icon: Icons.info_outline,
                      title: 'Instructions',
                      value: _medication!.instructions,
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Start date
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    title: 'Start Date',
                    value: DateFormat('MMM d, yyyy').format(_medication!.startDate),
                  ),
                  
                  if (_medication!.endDate != null) ...[
                    const SizedBox(height: 12),
                    
                    // End date
                    _buildInfoRow(
                      icon: Icons.event_busy,
                      title: 'End Date',
                      value: DateFormat('MMM d, yyyy').format(_medication!.endDate!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quantity and adherence cards in a row
          Row(
            children: [
              // Quantity card
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Supply',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Text(
                          '${_medication!.remainingQuantity}/${_medication!.totalQuantity}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: remainingPercentage,
                            backgroundColor: Colors.grey.shade200,
                            color: _getQuantityColor(
                              _medication!.remainingQuantity, 
                              _medication!.totalQuantity
                            ),
                            minHeight: 8,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          remainingPercentage <= 0.2
                              ? 'Refill soon!'
                              : 'Supply sufficient',
                          style: TextStyle(
                            color: remainingPercentage <= 0.2
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Adherence card
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adherence',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Text(
                          '${adherenceRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: adherenceColor,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Rating icon
                        Row(
                          children: [
                            Icon(
                              adherenceRate >= 80
                                  ? Icons.sentiment_very_satisfied
                                  : adherenceRate >= 50
                                      ? Icons.sentiment_neutral
                                      : Icons.sentiment_very_dissatisfied,
                              color: adherenceColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              adherenceRate >= 80
                                  ? 'Excellent'
                                  : adherenceRate >= 50
                                      ? 'Good'
                                      : 'Needs Improvement',
                              style: TextStyle(
                                color: adherenceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Next dose card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Dose',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Find next scheduled dose
                  _buildNextDoseInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScheduleTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Schedule card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dosage Schedule',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                
                // List of schedules
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _medication!.schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _medication!.schedules[index];
                    
                    // Format time
                    final hour = schedule.timeOfDay.hour;
                    final minute = schedule.timeOfDay.minute.toString().padLeft(2, '0');
                    final period = hour >= 12 ? 'PM' : 'AM';
                    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                    final timeString = '$hour12:$minute $period';
                    
                    // Format days
                    final days = _formatDaysOfWeek(schedule.daysOfWeek);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppTheme.primaryColor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeString,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  days,
                                  style: const TextStyle(
                                    color: AppTheme.lightTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Calendar view or weekly schedule could be added here
      ],
    );
  }
  
  Widget _buildHistoryTab() {
    // Sort logs by date, most recent first
    final logs = List<MedicationLog>.from(_medication!.logs)
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // History card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                
                // List of logs
                logs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No medication history yet'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          
                          // Group logs by date
                          final bool showDate = index == 0 || 
                              !_isSameDay(logs[index - 1].scheduledTime, log.scheduledTime);
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDate) ...[
                                if (index > 0) const SizedBox(height: 16),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(log.scheduledTime),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Divider(),
                              ],
                              
                              // Log entry
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    // Status icon
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: log.taken ? Colors.green.shade100 : Colors.red.shade100,
                                      ),
                                      child: Icon(
                                        log.taken ? Icons.check : Icons.close,
                                        color: log.taken ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Log details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log.taken ? 'Taken' : 'Missed',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: log.taken ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          Text(
                                            'Scheduled: ${DateFormat('h:mm a').format(log.scheduledTime)}',
                                            style: const TextStyle(
                                              color: AppTheme.lightTextColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (log.taken && log.takenTime != null)
                                            Text(
                                              'Taken: ${DateFormat('h:mm a').format(log.takenTime!)}',
                                              style: const TextStyle(
                                                color: AppTheme.lightTextColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (log.notes != null && log.notes!.isNotEmpty)
                                            Text(
                                              'Note: ${log.notes}',
                                              style: const TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper function to build info row
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
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
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper to determine quantity color
  Color _getQuantityColor(int remaining, int total) {
    final percentage = (remaining / total) * 100;
    
    if (percentage <= 20) {
      return Colors.red;
    } else if (percentage <= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  // Helper to format days of week
  String _formatDaysOfWeek(List<int> days) {
    if (days.length == 7) {
      return 'Every day';
    }
    
    if (days.length == 5 && 
        days.contains(1) && 
        days.contains(2) && 
        days.contains(3) && 
        days.contains(4) && 
        days.contains(5)) {
      return 'Weekdays';
    }
    
    if (days.length == 2 && 
        days.contains(6) && 
        days.contains(7)) {
      return 'Weekends';
    }
    
    final dayNames = days.map((day) {
      switch (day) {
        case 1: return 'Mon';
        case 2: return 'Tue';
        case 3: return 'Wed';
        case 4: return 'Thu';
        case 5: return 'Fri';
        case 6: return 'Sat';
        case 7: return 'Sun';
        default: return '';
      }
    }).join(', ');
    
    return dayNames;
  }
  
  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // Helper to build next dose information
  Widget _buildNextDoseInfo() {
    // Get current date and time
    final now = DateTime.now();
    final today = now.weekday;
    
    // Find the next scheduled dose
    Schedule? nextSchedule;
    DateTime? nextDoseTime;
    
    // First, check if there's a dose scheduled for today
    for (final schedule in _medication!.schedules) {
      if (schedule.daysOfWeek.contains(today)) {
        final scheduleTime = DateTime(
          now.year,
          now.month,
          now.day,
          schedule.timeOfDay.hour,
          schedule.timeOfDay.minute,
        );
        
        // If the schedule is in the future today
        if (scheduleTime.isAfter(now)) {
          if (nextDoseTime == null || scheduleTime.isBefore(nextDoseTime)) {
            nextSchedule = schedule;
            nextDoseTime = scheduleTime;
          }
        }
      }
    }
    
    // If no dose found for today, find the next one in the coming days
    if (nextDoseTime == null) {
      int daysToAdd = 1;
      while (daysToAdd <= 7 && nextDoseTime == null) {
        final nextDay = (today + daysToAdd) % 7;
        final actualDay = nextDay == 0 ? 7 : nextDay; // Convert 0 to 7 for Sunday
        
        for (final schedule in _medication!.schedules) {
          if (schedule.daysOfWeek.contains(actualDay)) {
            final scheduleTime = DateTime(
              now.year,
              now.month,
              now.day,
              schedule.timeOfDay.hour,
              schedule.timeOfDay.minute,
            ).add(Duration(days: daysToAdd));
            
            if (nextDoseTime == null || scheduleTime.isBefore(nextDoseTime)) {
              nextSchedule = schedule;
              nextDoseTime = scheduleTime;
            }
          }
        }
        
        daysToAdd++;
      }
    }
    
    if (nextDoseTime == null) {
      return const Text('No upcoming doses scheduled');
    }
    
    // Calculate time difference
    final difference = nextDoseTime.difference(now);
    String timeUntil;
    
    if (difference.inHours < 1) {
      timeUntil = 'in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else if (difference.inHours < 24) {
      timeUntil = 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
      if (difference.inMinutes % 60 > 0) {
        timeUntil += ' and ${difference.inMinutes % 60} minute${difference.inMinutes % 60 == 1 ? '' : 's'}';
      }
    } else {
      timeUntil = 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
      if (difference.inHours % 24 > 0) {
        timeUntil += ' and ${difference.inHours % 24} hour${difference.inHours % 24 == 1 ? '' : 's'}';
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(nextDoseTime),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${DateFormat('EEEE, MMM d').format(nextDoseTime)} ($timeUntil)',
                  style: const TextStyle(
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        OutlinedButton.icon(
          onPressed: _takeMedication,
          icon: const Icon(Icons.check),
          label: const Text('TAKE NOW'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}