import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/medication_service.dart';
import '../../../config/theme.dart';

class AdherenceChart extends StatelessWidget {
  final MedicationAdherence adherence;
  
  const AdherenceChart({
    super.key,
    required this.adherence,
  });

  @override
  Widget build(BuildContext context) {
    // Format the overall adherence rate
    final adherenceRate = adherence.adherenceRate.toStringAsFixed(1);
    
    // Define color based on adherence rate
    Color rateColor;
    if (adherence.adherenceRate >= 80) {
      rateColor = Colors.green;
    } else if (adherence.adherenceRate >= 50) {
      rateColor = Colors.orange;
    } else {
      rateColor = Colors.red;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall adherence rate
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Adherence',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$adherenceRate%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: rateColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildAdherenceRatingIcon(adherence.adherenceRate),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Taken: ${adherence.totalTaken}/${adherence.totalScheduled}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Past ${_daysDifference(adherence.startDate, adherence.endDate)} days',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Daily adherence bars
            const Text(
              'Daily Adherence',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              height: 150,
              child: adherence.dailyAdherence.isEmpty
                  ? const Center(child: Text('No data available'))
                  : _buildDailyAdherenceChart(adherence.dailyAdherence),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to build adherence rating icon
  Widget _buildAdherenceRatingIcon(double rate) {
    IconData icon;
    Color color;
    
    if (rate >= 80) {
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (rate >= 50) {
      icon = Icons.sentiment_neutral;
      color = Colors.orange;
    } else {
      icon = Icons.sentiment_very_dissatisfied;
      color = Colors.red;
    }
    
    return Icon(icon, color: color);
  }
  
  // Helper to calculate days difference
  int _daysDifference(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }
  
  // Build daily adherence chart
  Widget _buildDailyAdherenceChart(List<DailyAdherence> dailyData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text('100%', style: TextStyle(fontSize: 10)),
            Text('75%', style: TextStyle(fontSize: 10)),
            Text('50%', style: TextStyle(fontSize: 10)),
            Text('25%', style: TextStyle(fontSize: 10)),
            Text('0%', style: TextStyle(fontSize: 10)),
          ],
        ),
        
        const SizedBox(width: 8),
        
        // Bars
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: dailyData.map((day) {
              // Determine bar color based on adherence rate
              Color barColor;
              if (day.rate >= 80) {
                barColor = Colors.green;
              } else if (day.rate >= 50) {
                barColor = Colors.orange;
              } else if (day.rate > 0) {
                barColor = Colors.red;
              } else {
                barColor = Colors.grey.shade300;
              }
              
              // Bar height based on rate (max height is 120)
              final barHeight = day.scheduled > 0 ? (day.rate / 100) * 120 : 0;
              
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: barHeight,
                      width: 20,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Date label
                    Text(
                      DateFormat('E\nd').format(day.date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}