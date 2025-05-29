import 'package:flutter/material.dart';

class ContentManagementHelpPage extends StatelessWidget {
  const ContentManagementHelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content Management Help')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Management Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'The Content Management section allows administrators to manage two types of content: FAQs and Event Slider. This ensures users have access to up-to-date information and announcements.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              'Managing FAQs:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.list, color: Colors.blueGrey),
              title: Text('Viewing FAQs'),
              subtitle: Text('See a list of frequently asked questions and their answers, sorted by creation date.'),
            ),
            ListTile(
              leading: Icon(Icons.search, color: Colors.blueGrey),
              title: Text('Searching FAQs'),
              subtitle: Text('Search FAQs by question, answer, or category using the search bar.'),
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: Colors.green),
              title: Text('Adding New FAQs'),
              subtitle: Text('Add new questions and answers to the FAQ list. Include a category for better organization.'),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.orange),
              title: Text('Editing FAQs'),
              subtitle: Text('Modify existing FAQ entries, including the question, answer, and category.'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Deleting FAQs'),
              subtitle: Text('Remove FAQs that are no longer relevant or have been updated elsewhere.'),
            ),
            SizedBox(height: 24),
            Text(
              'Managing Event Slider:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.list, color: Colors.blueGrey),
              title: Text('Viewing Events'),
              subtitle: Text('See the four event slides that appear on the home page, ordered by their display order.'),
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: Colors.green),
              title: Text('Adding New Events'),
              subtitle: Text('Create new event slides with title, content, and optional image. Note: Only 4 events are allowed.'),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.orange),
              title: Text('Editing Events'),
              subtitle: Text('Modify existing event slides, including title, content, image, and active status.'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Deleting Events'),
              subtitle: Text('Remove event slides. The system will maintain exactly 4 events, creating default ones if needed.'),
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
              '- Keep FAQs organized by using appropriate categories.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Regularly update FAQs based on common user queries.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Ensure event slides are engaging and up-to-date.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Use images in event slides to make them more visually appealing.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '- Remember that only 4 event slides can be displayed at a time.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}