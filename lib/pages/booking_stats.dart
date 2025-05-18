import 'package:flutter/material.dart';

class BookingStatsPage extends StatelessWidget {
  const BookingStatsPage({Key? key}) : super(key: key);

  // Dummy data
  final List<Map<String, dynamic>> bookings = const [
    {
      'user': 'John Doe',
      'room': 'Ruang A',
      'date': '2025-05-20',
    },
    {
      'user': 'Jane Smith',
      'room': 'Ruang B',
      'date': '2025-05-22',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Stats'),
      ),
      body: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text('${booking['user']} - ${booking['room']}'),
              subtitle: Text('Tanggal: ${booking['date']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      // TODO: handle accept booking
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      // TODO: handle decline booking
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
