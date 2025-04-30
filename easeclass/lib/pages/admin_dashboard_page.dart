import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('User Management'),
                subtitle: const Text('View and manage users'),
                onTap: () {
                  // TODO: Navigate to user management page
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.meeting_room),
                title: const Text('Room Management'),
                subtitle: const Text('View and manage rooms'),
                onTap: () {
                  // TODO: Navigate to room management page
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Booking Stats'),
                subtitle: const Text('View booking statistics'),
                onTap: () {
                  // TODO: Navigate to booking stats page
                },
              ),
            ),
            // Add more admin features here
          ],
        ),
      ),
    );
  }
} 