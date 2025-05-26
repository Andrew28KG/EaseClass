import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login page and clear all previous routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
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
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          const ListTile(
            title: Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(FirebaseAuth.instance.currentUser?.email ?? 'User'),
            subtitle: const Text('Edit your profile'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // Handle profile edit
            },
          ),
          const Divider(),

          // Account Settings Section
          const ListTile(
            title: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle notifications settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Privacy & Security'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle privacy settings
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
            title: const Text('About EaseClass'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'EaseClass',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
                children: const [
                  Text(
                    'EaseClass is a classroom booking system that helps students and teachers manage their classroom reservations efficiently.',
                  ),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Handle help & support
            },
          ),
          const Divider(),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
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
    );
  }
} 