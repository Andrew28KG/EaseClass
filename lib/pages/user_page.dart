import 'package:flutter/material.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int _selectedIndex = 0;

  // List of available rooms
  final List<Map<String, dynamic>> availableRooms = [
    {'room': '101', 'building': 'A', 'floor': 1, 'time': '09:00 - 11:00'},
    {'room': '102', 'building': 'A', 'floor': 1, 'time': '13:00 - 15:00'},
    {'room': '202', 'building': 'B', 'floor': 2, 'time': '10:00 - 12:00'},
    {'room': '301', 'building': 'C', 'floor': 3, 'time': '14:00 - 16:00'},
  ];

  // List of booked classrooms
  final List<Map<String, dynamic>> myBookings = [
    {'room': '201', 'building': 'B', 'floor': 2, 'date': 'Today', 'time': '11:00 - 13:00'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EaseClass'),
        actions: [
          // Admin button
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Dashboard',
            onPressed: () {
              Navigator.pushNamed(context, '/admin');
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildHomeTab() : _buildBookingsTab(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'My Bookings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to EaseClass!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Book your classroom easily with just a few taps.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to available rooms
                      },
                      child: const Text('Browse Classrooms'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Available rooms section
            const Text(
              'Available Now',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableRooms.length,
              itemBuilder: (context, index) {
                final room = availableRooms[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.meeting_room, color: Colors.green),
                    title: Text('Room ${room['room']}'),
                    subtitle: Text(
                      'Building ${room['building']} - Floor ${room['floor']}\nAvailable: ${room['time']}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Book room
                      },
                      child: const Text('Book'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          myBookings.isEmpty
              ? const Center(
                  child: Text(
                    'You have no bookings yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myBookings.length,
                  itemBuilder: (context, index) {
                    final booking = myBookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.event_available, color: Colors.blue),
                        title: Text('Room ${booking['room']}'),
                        subtitle: Text(
                          'Building ${booking['building']} - Floor ${booking['floor']}\n${booking['date']} ${booking['time']}',
                        ),
                        trailing: OutlinedButton(
                          onPressed: () {
                            // Cancel booking
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
} 