import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: ListView.builder(
        itemCount: 5, // Replace with actual booking count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(index),
                child: Icon(
                  _getStatusIcon(index),
                  color: Colors.white,
                ),
              ),
              title: Text('Room ${101 + index}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${DateTime.now().add(Duration(days: index)).toString().split(' ')[0]}'),
                  Text('Time: ${9 + index}:00 - ${10 + index}:00'),
                  Text('Status: ${_getStatusText(index)}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/progress-detail',
                  arguments: {
                    'bookingId': index + 1,
                    'roomId': 101 + index,
                    'date': DateTime.now().add(Duration(days: index)).toString().split(' ')[0],
                    'time': '${9 + index}:00 - ${10 + index}:00',
                    'status': _getStatusText(index),
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(int index) {
    switch (index % 3) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int index) {
    switch (index % 3) {
      case 0:
        return Icons.check_circle;
      case 1:
        return Icons.pending;
      case 2:
        return Icons.schedule;
      default:
        return Icons.error;
    }
  }

  String _getStatusText(int index) {
    switch (index % 3) {
      case 0:
        return 'Completed';
      case 1:
        return 'Pending';
      case 2:
        return 'Upcoming';
      default:
        return 'Unknown';
    }
  }
} 