import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pillpal/models/medication.dart';
import 'package:pillpal/config/theme.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final DateTime dueTime;
  final int minutesUntilDue;
  final VoidCallback onTaken;
  
  const MedicationCard({
    super.key,
    required this.medication,
    required this.dueTime,
    required this.minutesUntilDue,
    required this.onTaken,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color based on how close to due time
    Color statusColor;
    String statusText;
    
    if (minutesUntilDue < 0) {
      // Overdue
      statusColor = Colors.red;
      statusText = 'Overdue';
    } else if (minutesUntilDue < 15) {
      // Due soon
      statusColor = Colors.orange;
      statusText = 'Due soon';
    } else {
      // Upcoming
      statusColor = Colors.green;
      statusText = 'Upcoming';
    }
    
    // Format time
    final timeFormat = DateFormat('h:mm a');
    final formattedTime = timeFormat.format(dueTime);
    
    // Calculate remaining time text
    String remainingTimeText;
    if (minutesUntilDue < 0) {
      remainingTimeText = '${-minutesUntilDue} minutes ago';
    } else if (minutesUntilDue < 60) {
      remainingTimeText = 'in $minutesUntilDue minutes';
    } else {
      final hours = (minutesUntilDue / 60).floor();
      final minutes = minutesUntilDue % 60;
      remainingTimeText = 'in $hours hour${hours > 1 ? 's' : ''}${minutes > 0 ? ' $minutes min' : ''}';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication name and status
            Row(
              children: [
                const Icon(Icons.medication, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    medication.name,
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
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Dosage and time
            Row(
              children: [
                const Icon(Icons.medical_information, size: 16, color: AppTheme.lightTextColor),
                const SizedBox(width: 8),
                Text(
                  'Take ${medication.dosage} ${medication.dosageUnit.name}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppTheme.lightTextColor),
                const SizedBox(width: 8),
                Text(
                  '$formattedTime ($remainingTimeText)',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            if (medication.instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.lightTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      medication.instructions,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Open medication details
                    // This will be implemented later
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('DETAILS'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onTaken,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: minutesUntilDue < 0 ? Colors.red : AppTheme.primaryColor,
                  ),
                  child: const Text('TAKEN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}