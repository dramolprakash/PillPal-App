import 'package:flutter/material.dart';

class NextDoseCard extends StatelessWidget {
  const NextDoseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Next Dose',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.medication, color: Colors.blue),
              title: const Text('Medication Name'),
              subtitle: const Text('2 pills'),
              trailing: const Text('In 2 hours'),
            ),
          ],
        ),
      ),
    );
  }
}