import 'package:flutter/material.dart';

class ClassManagementHelpPage extends StatelessWidget {
  const ClassManagementHelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Management Help')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Management Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'The Class Management section allows administrators to manage the available classrooms. This includes adding new classrooms, editing their details, and removing classrooms that are no longer needed. These classrooms are what users can see and book.',
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
              title: Text('Viewing Classes'),
              subtitle: Text('See a list of all available classrooms with their basic information like name, building, floor, and capacity.'),
            ),
            ListTile(
              leading: Icon(Icons.filter_list, color: Colors.blueGrey),
              title: Text('Filtering Classes'),
              subtitle: Text('Filter classes by building, floor, capacity, and availability. Sort classes by rating.'),
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: Colors.green),
              title: Text('Adding New Classes'),
              subtitle: Text('Create new classroom entries by providing details like name, description, building, floor, and capacity.'),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.orange),
              title: Text('Editing Class Details'),
              subtitle: Text('Modify existing classroom information, including name, description, building, floor, capacity, and availability.'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Deleting Classes'),
              subtitle: Text('Remove classrooms that are no longer needed. Be mindful of existing bookings when deleting.'),
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
              '- Keep classroom details up-to-date to provide accurate information to users.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Consider the impact on current or future bookings before deleting a classroom.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Use filters to quickly find specific classrooms or manage large numbers of classrooms.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Ensure all required fields are filled when adding or editing classrooms.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 