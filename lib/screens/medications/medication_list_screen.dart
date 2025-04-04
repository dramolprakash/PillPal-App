import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/medication_service.dart';
import '../../models/medication.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
      ),
      body: Consumer<MedicationService>(
        builder: (context, medicationService, child) {
          final medications = medicationService.medications;
          
          if (medications.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              await medicationService.loadMedications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return _buildMedicationItem(context, medication);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.addMedication);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medication_outlined,
            size: 80,
            color: AppTheme.lightTextColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Medications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first medication to get started',
            style: TextStyle(
              color: AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.addMedication);
            },
            icon: const Icon(Icons.add),
            label: const Text('ADD MEDICATION'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMedicationItem(BuildContext context, Medication medication) {
    // Calculate adherence rate
    final adherenceRate = medication.getComplianceRate();
    
    // Determine adherence color
    Color adherenceColor;
    if (adherenceRate >= 80) {
      adherenceColor = Colors.green;
    } else if (adherenceRate >= 50) {
      adherenceColor = Colors.orange;
    } else {
      adherenceColor = Colors.red;
    }
    
    // Create a string of schedule times
    final scheduleTexts = medication.schedules.map((schedule) {
      return schedule.getFormattedTime();
    }).join(', ');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.medicationDetail,
            arguments: {'id': medication.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication name and adherence
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
                      color: adherenceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${adherenceRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: adherenceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Dosage
              Row(
                children: [
                  const Icon(Icons.medical_information, size: 16, color: AppTheme.lightTextColor),
                  const SizedBox(width: 8),
                  Text(
                    'Take ${medication.dosage} ${medication.dosageUnit.name} ${medication.frequency} time(s) daily',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Schedule
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppTheme.lightTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scheduleTexts,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Quantity
              Row(
                children: [
                  const Icon(Icons.inventory_2, size: 16, color: AppTheme.lightTextColor),
                  const SizedBox(width: 8),
                  Text(
                    'Remaining: ${medication.remainingQuantity}/${medication.totalQuantity} ${medication.dosageUnit.name}s',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Progress bar for remaining quantity
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: medication.remainingQuantity / medication.totalQuantity,
                  backgroundColor: Colors.grey.shade200,
                  color: _getQuantityColor(medication.remainingQuantity, medication.totalQuantity),
                  minHeight: 8,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Edit medication
                      Navigator.of(context).pushNamed(
                        AppRoutes.addMedication,
                        arguments: {'id': medication.id},
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('EDIT'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.medicationDetail,
                        arguments: {'id': medication.id},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('DETAILS'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
}