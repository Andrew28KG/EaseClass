import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to admin login page and clear all previous routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin-login',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error logging out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _logout(context);
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${FirebaseAuth.instance.currentUser?.email ?? 'Admin'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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