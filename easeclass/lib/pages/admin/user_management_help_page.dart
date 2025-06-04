import 'package:flutter/material.dart';

class UserManagementHelpPage extends StatelessWidget {
  const UserManagementHelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management Help')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'The User Management section allows administrators to manage user accounts. This includes viewing user details, adding new users, editing user information, and managing user roles (student or teacher).',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              'Key Features:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.list, color: Colors.blueGrey),
              title: Text('Viewing Users'),
              subtitle: Text('See a list of all users with their basic information like email, role, and department.'),
            ),
            ListTile(
              leading: Icon(Icons.search, color: Colors.blueGrey),
              title: Text('Searching Users'),
              subtitle: Text('Use the search bar to quickly find specific users by email or name.'),
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: Colors.green),
              title: Text('Adding New Users'),
              subtitle: Text('Create new user accounts by providing email, password, role (student/teacher), and department.'),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.orange),
              title: Text('Editing User Details'),
              subtitle: Text('Modify existing user information, including role and department.'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Deleting Users'),
              subtitle: Text('Remove user accounts. Note: This only removes the user from Firestore, not from Firebase Authentication.'),
            ),
            ListTile(
              leading: Icon(Icons.lock_reset_outlined, color: Colors.purpleAccent),
              title: Text('Password Management'),
              subtitle: Text('Set initial passwords for new users. Users can change their passwords after logging in.'),
            ),
            SizedBox(height: 24),
            Text(
              'Tips for Use:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '- Ensure you have the necessary permissions to perform these actions.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- When adding users, communicate the initial password securely.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Understand the difference between deleting a user from Firestore and Firebase Authentication.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Use the search function to quickly find specific users in large lists.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Keep user roles and departments up-to-date for proper access control.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}