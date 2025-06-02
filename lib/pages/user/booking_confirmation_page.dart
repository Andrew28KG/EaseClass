import 'package:flutter/material.dart';
import '../../utils/navigation_helper.dart'; // Import navigation helper

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({Key? key}) : super(key: key);

  @override  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    // Handle roomId which could be String or int
    final dynamic roomIdValue = args['roomId'];
    final roomId = roomIdValue is int ? roomIdValue : roomIdValue.toString();
    final String building = args['building'];
    // Handle floor value which could be int or String
    final dynamic floorValue = args['floor'];
    final int floor = floorValue is int ? floorValue : int.tryParse(floorValue.toString()) ?? 0;
    final String date = args['date'];
    final String timeSlot = args['timeSlot'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Room', 'Room $roomId'),
                      _buildInfoRow('Building', building),
                      _buildInfoRow('Floor', 'Floor $floor'),
                      _buildInfoRow('Date', date),
                      _buildInfoRow('Time', timeSlot),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Additional Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Booking ID', 'BK${DateTime.now().millisecondsSinceEpoch}'),
                      _buildInfoRow('Status', 'Pending'),
                      _buildInfoRow('Created At', DateTime.now().toString().split('.')[0]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Terms and Conditions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terms and Conditions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '1. Please arrive 5 minutes before your scheduled time.\n'
                        '2. Clean up after using the room.\n'
                        '3. Report any issues to the administration.\n'
                        '4. Cancellations must be made at least 24 hours in advance.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Show success dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Booking Confirmed'),
                        content: const Text('Your room has been successfully booked!'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              // Return to available rooms tab
                              NavigationHelper.navigateToAvailableRooms(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Confirm Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 