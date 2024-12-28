import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: ListView.builder(
        itemCount: 5, // Example count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: Text('Medication ${index + 1}'),
              subtitle: const Text('2 pills - 8:00 AM'),
            ),
          );
        },
      ),
    );
  }
}
