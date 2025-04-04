import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/medication_service.dart';
import '../../models/medication.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          _buildDateSelector(),
          
          // Schedule list
          Expanded(
            child: Consumer<MedicationService>(
              builder: (context, medicationService, child) {
                return _buildScheduleList(medicationService);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateSelector() {
    // Get week dates
    final List<DateTime> weekDates = [];
    final today = DateTime.now();
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    
    for (int i = 0; i < 7; i++) {
      weekDates.add(weekStart.add(Duration(days: i)));
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month and year header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime.now();
                        });
                      },
                      child: const Text('Today'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Days of week
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weekDates.length,
              itemBuilder: (context, index) {
                final date = weekDates[index];
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, today);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 7,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white 
                                : AppTheme.lightTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday && !isSelected
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : Colors.transparent,
                            border: isToday && !isSelected
                                ? Border.all(color: AppTheme.primaryColor)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected 
                                    ? Colors.white 
                                    : isToday
                                        ? AppTheme.primaryColor
                                        : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScheduleList(MedicationService medicationService) {
    // Get all medications
    final medications = medicationService.medications;
    
    // Get schedules for the selected date
    final dayOfWeek = _selectedDate.weekday;
    final List<ScheduleItem> schedules = [];
    
    for (final medication in medications) {
      for (final schedule in medication.schedules) {
        if (schedule.daysOfWeek.contains(dayOfWeek)) {
          // Create a datetime for this schedule on the selected date
          final scheduleTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            schedule.timeOfDay.hour,
            schedule.timeOfDay.minute,
          );
          
          // Check if it's already been taken
          bool taken = false;
          MedicationLog? log;
          
          for (final l in medication.logs) {
            if (_isSameDay(l.scheduledTime, scheduleTime) &&
                l.scheduledTime.hour == scheduleTime.hour &&
                l.scheduledTime.minute == scheduleTime.minute) {
              taken = l.taken;
              log = l;
              break;
            }
          }
          
          schedules.add(ScheduleItem(
            medication: medication,
            schedule: schedule,
            dateTime: scheduleTime,
            taken: taken,
            log: log,
          ));
        }
      }
    }
    
    // Sort by time
    schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    // Group by hour
    final Map<int, List<ScheduleItem>> hourlySchedules = {};
    for (final item in schedules) {
      final hour = item.dateTime.hour;
      if (!hourlySchedules.containsKey(hour)) {
        hourlySchedules[hour] = [];
      }
      hourlySchedules[hour]!.add(item);
    }
    
    // Convert to sorted list of hours
    final List<int> sortedHours = hourlySchedules.keys.toList()..sort();
    
    if (sortedHours.isEmpty) {
      return const Center(
        child: Text('No medications scheduled for this day'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedHours.length,
      itemBuilder: (context, index) {
        final hour = sortedHours[index];
        final itemsForHour = hourlySchedules[hour]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hour header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('h a').format(DateTime(2022, 1, 1, hour)),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            
            // Schedule items for this hour
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsForHour.length,
              itemBuilder: (context, itemIndex) {
                final item = itemsForHour[itemIndex];
                return _buildScheduleItem(item, medicationService);
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildScheduleItem(ScheduleItem item, MedicationService medicationService) {
    final now = DateTime.now();
    final isPast = item.dateTime.isBefore(now);
    final isFuture = item.dateTime.isAfter(now);
    final isNow = item.dateTime.difference(now).inMinutes.abs() < 30;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (item.taken) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Taken';
    } else if (isPast && !item.taken) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Missed';
    } else if (isNow) {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
      statusText = 'Due now';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
      statusText = 'Upcoming';
    }
    
    return Card(
      margin: const EdgeInsets.only(left: 24, right: 0, bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm').format(item.dateTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('a').format(item.dateTime),
                  style: TextStyle(
                    color: AppTheme.lightTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 24),
            
            // Medication info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medication.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${item.medication.dosage} ${item.medication.dosageUnit.name}',
                    style: const TextStyle(
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                  if (item.medication.instructions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.medication.instructions,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Status and action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                        statusIcon,
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
                
                const SizedBox(height: 8),
                
                if (!item.taken && (_isSameDay(item.dateTime, now) || item.dateTime.isBefore(now)))
                  TextButton(
                    onPressed: () async {
                      await medicationService.logMedicationTaken(
                        item.medication.id!,
                        item.dateTime,
                      );
                      
                      if (!mounted) return;
                      setState(() {}); // Refresh UI
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medication marked as taken'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('TAKE NOW'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Helper class to represent a scheduled medication
class ScheduleItem {
  final Medication medication;
  final Schedule schedule;
  final DateTime dateTime;
  final bool taken;
  final MedicationLog? log;
  
  ScheduleItem({
    required this.medication,
    required this.schedule,
    required this.dateTime,
    required this.taken,
    this.log,
  });
}