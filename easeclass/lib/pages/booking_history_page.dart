import 'package:flutter/material.dart';
import '../services/booking_service.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({Key? key}) : super(key: key);

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pastBookings = [];

  @override
  void initState() {
    super.initState();
    _loadPastBookings();
  }

  Future<void> _loadPastBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get completed and cancelled bookings
      final completedBookings = await _bookingService.getBookingsByStatus('completed').first;
      final cancelledBookings = await _bookingService.getBookingsByStatus('cancelled').first;
      final rejectedBookings = await _bookingService.getBookingsByStatus('rejected').first;

      if (mounted) {
        setState(() {
          _pastBookings = [
            ...completedBookings.map((booking) => booking.toMap()),
            ...cancelledBookings.map((booking) => booking.toMap()),
            ...rejectedBookings.map((booking) => booking.toMap()),
          ];
          // Sort by date, most recent first
          _pastBookings.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading past bookings: $e');
      // Use dummy data in case of error
      setState(() {
        _pastBookings = [
          {
            'id': '1',
            'userName': 'John Doe',
            'roomName': 'Room A101',
            'building': 'A',
            'floor': '1',
            'capacity': 30,
            'features': ['Projector', 'Whiteboard', 'AC'],
            'date': '2025-05-10',
            'time': '09:00 - 11:00',
            'purpose': 'Programming Class',
            'status': 'completed',
            'createdAt': DateTime(2025, 5, 10),
          },
          {
            'id': '2',
            'userName': 'Jane Smith',
            'roomName': 'Room B202',
            'building': 'B',
            'floor': '2',
            'capacity': 20,
            'features': ['Whiteboard', 'AC'],
            'date': '2025-05-08',
            'time': '14:00 - 16:00',
            'purpose': 'Team Meeting',
            'status': 'cancelled',
            'createdAt': DateTime(2025, 5, 8),
          },
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadPastBookings,
            child: _pastBookings.isEmpty
                ? const Center(
                    child: Text(
                      'No booking history found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _pastBookings.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final booking = _pastBookings[index];
                      return _buildBookingHistoryCard(booking);
                    },
                  ),
          );
  }

  Widget _buildBookingHistoryCard(Map<String, dynamic> booking) {
    // Determine color based on status
    Color statusColor;
    IconData statusIcon;

    switch (booking['status'].toString().toLowerCase()) {
      case 'completed':
        statusColor = Colors.teal;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'rejected':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          booking['roomName'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${booking['date']} | ${booking['time']}',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Purpose: ${booking['purpose']}',
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            booking['status'].toString().toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _showBookingDetailsDialog(booking),
      ),
    );
  }

  void _showBookingDetailsDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking['roomName']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Date', booking['date']),
            _buildDetailRow('Time', booking['time']),
            _buildDetailRow('User', booking['userName']),
            _buildDetailRow('Purpose', booking['purpose'] ?? 'Not specified'),
            _buildDetailRow('Status', booking['status'].toString().toUpperCase()),
            _buildDetailRow('Building', booking['building']),
            _buildDetailRow('Floor', booking['floor']),
            _buildDetailRow('Capacity', booking['capacity']),
            if (booking['features'] != null && booking['features'] is List)
              _buildDetailRow('Features', (booking['features'] as List).join(', ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, dynamic value) {
    // Ensure value is a string no matter what type it is
    final String stringValue = value?.toString() ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(stringValue),
          ),
        ],
      ),
    );
  }
}
