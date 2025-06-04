import 'package:flutter/material.dart';
import '../../utils/navigation_helper.dart'; // Import navigation helper

class ProgressDetailPage extends StatefulWidget {
  const ProgressDetailPage({Key? key}) : super(key: key);

  @override
  State<ProgressDetailPage> createState() => _ProgressDetailPageState();
}

class _ProgressDetailPageState extends State<ProgressDetailPage> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final int bookingId = args['bookingId'];
    final int roomId = args['roomId'];
    final String date = args['date'];
    final String time = args['time'];
    final String status = args['status'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #$bookingId'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusRow('Room', 'Room $roomId'),
                      _buildStatusRow('Date', date),
                      _buildStatusRow('Time', time),
                      _buildStatusRow('Status', status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Booking Timeline
              const Text(
                'Booking Timeline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildTimelineItem(
                'Booking Requested',
                'Your booking request has been submitted',
                Icons.send,
                true,
              ),
              _buildTimelineItem(
                'Booking Confirmed',
                'Your booking has been confirmed',
                Icons.check_circle,
                true,
              ),
              _buildTimelineItem(
                'Class Completed',
                'The class has been completed',
                Icons.event_available,
                status == 'Completed',
              ),
              _buildTimelineItem(
                'Rating Submitted',
                'You have rated this booking',
                Icons.star,
                false,
              ),
              const SizedBox(height: 20),

              // Rating Button (only show if class is completed)
              if (status == 'Completed')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      NavigationHelper.navigateToRating(
                        context,
                        {
                          'bookingId': bookingId,
                          'roomId': roomId,
                          'date': date,
                          'time': time,
                        },
                      );
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Rate This Booking'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
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

  Widget _buildTimelineItem(String title, String subtitle, IconData icon, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isCompleted ? Colors.grey : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 