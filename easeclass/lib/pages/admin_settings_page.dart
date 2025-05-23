import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({Key? key}) : super(key: key);

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
      // AppBar is handled by AdminMainPage when embedded
      appBar: MediaQuery.of(context).size.width <= 600 ? AppBar(
        title: const Text('Admin Settings'),
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Completely rectangular shape
        ),
        backgroundColor: Colors.orange, // Use orange for admin pages
      ) : null,
      body: ListView(
        children: [
          // Profile Section
          const ListTile(
            title: Text(
              'Admin Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.admin_panel_settings, color: Colors.white),
            ),
            title: Text(FirebaseAuth.instance.currentUser?.email ?? 'Admin User'),
            subtitle: const Text('Admin Account'),
          ),
          const Divider(),

          // Admin Settings Section
          const ListTile(
            title: Text(
              'Admin Controls',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.room_preferences),
            title: const Text('Room Management'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to room management
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle user management
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('System Settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle system settings
            },
          ),
          const Divider(),

          // About Section
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About EaseClass Admin'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'EaseClass Admin',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
                children: const [
                  Text(
                    'EaseClass Admin is the administrative panel for the EaseClass classroom booking system.',
                  ),
                ],
              );
            },
          ),
          const Divider(),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout from Admin',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout from the admin dashboard?'),
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
    );
  }
}
