import 'package:flutter/material.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  // Dummy data
  final List<Map<String, dynamic>> userRequests = const [
    {
      'name': 'John Doe',
      'request': 'Pinjam Ruangan A + Proyektor',
    },
    {
      'name': 'Jane Smith',
      'request': 'Tambahan Meja di Ruangan B',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button navigation
      child: Scaffold(        // No AppBar to prevent double headers
        body: ListView.builder(
        itemCount: userRequests.length,
        itemBuilder: (context, index) {
          final user = userRequests[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(user['name']),
              subtitle: Text(user['request']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      // TODO: handle accept
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      // TODO: handle decline
                    },
                  ),
                ],
              ),
            ),          );
        },
        ),
      ),
    );
  }
}