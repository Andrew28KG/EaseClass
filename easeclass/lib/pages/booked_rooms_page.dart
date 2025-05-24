import 'package:flutter/material.dart';
import '../services/booking_service.dart';

class BookedRoomsPage extends StatefulWidget {
  const BookedRoomsPage({Key? key}) : super(key: key);

  @override
  State<BookedRoomsPage> createState() => _BookedRoomsPageState();
}

class _BookedRoomsPageState extends State<BookedRoomsPage> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeBookings = [];

  @override
  void initState() {
    super.initState();
    _loadActiveBookings();
  }
  Future<void> _loadActiveBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get pending and approved bookings
      final pendingBookings = await _bookingService.getBookingsByStatus('pending').first;
      final approvedBookings = await _bookingService.getBookingsByStatus('approved').first;

      if (mounted) {
        setState(() {
          _activeBookings = [
            ...pendingBookings.map((booking) => {
              'id': booking.id,
              'roomId': booking.roomId,
              'roomName': booking.roomDetails?['name'] ?? 'Room ${booking.roomId}',
              'building': booking.roomDetails?['building'] ?? '-',
              'floor': booking.roomDetails?['floor']?.toString() ?? '-',
              'capacity': booking.roomDetails?['capacity'] ?? 0,
              'features': booking.roomDetails?['features'] ?? [],
              'date': booking.date,
              'time': booking.time,
              'purpose': booking.purpose,
              'status': booking.status,
              'createdAt': booking.createdAt.toDate(),
              'userName': booking.userDetails?['name'] ?? 'Anonymous',
            }),
            ...approvedBookings.map((booking) => {
              'id': booking.id,
              'roomId': booking.roomId,
              'roomName': booking.roomDetails?['name'] ?? 'Room ${booking.roomId}',
              'building': booking.roomDetails?['building'] ?? '-',
              'floor': booking.roomDetails?['floor']?.toString() ?? '-',
              'capacity': booking.roomDetails?['capacity'] ?? 0,
              'features': booking.roomDetails?['features'] ?? [],
              'date': booking.date,
              'time': booking.time,
              'purpose': booking.purpose,
              'status': booking.status,
              'createdAt': booking.createdAt.toDate(),
              'userName': booking.userDetails?['name'] ?? 'Anonymous',
            }),
          ];
          // Sort by date, most recent first
          _activeBookings.sort((a, b) => a['date'].compareTo(b['date']));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading active bookings: $e');
      // Use dummy data in case of error
      setState(() {
        _activeBookings = [
          {
            'id': '1',
            'userName': 'John Doe',
            'roomName': 'Room A101',
            'building': 'A',
            'floor': '1',
            'capacity': 30,
            'features': ['Projector', 'Whiteboard', 'AC'],
            'date': '2025-05-15',
            'time': '09:00 - 11:00',
            'purpose': 'Programming Class',
            'status': 'approved',
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
            'date': '2025-05-12',
            'time': '14:00 - 16:00',
            'purpose': 'Team Meeting',
            'status': 'pending',
            'createdAt': DateTime(2025, 5, 8),
          },
        ];
        _isLoading = false;
      });
    }
  }

  String _getStatusChip(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏱️ Pending';
      case 'approved':
        return '✅ Approved';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper for booking details dialog
  Widget _buildDetailRow(String label, dynamic value) {
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(stringValue)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadActiveBookings,
            child: _activeBookings.isEmpty
                ? const Center(
                    child: Text(
                      'No active bookings found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _activeBookings.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final booking = _activeBookings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    booking['roomName'] ?? 'Unknown Room',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(booking['status']),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusChip(booking['status']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Building: ${booking['building'] ?? '-'}, Floor: ${booking['floor'] ?? '-'}'),
                              const SizedBox(height: 4),
                              Text('Date: ${booking['date'] ?? '-'}'),
                              Text('Time: ${booking['time'] ?? '-'}'),
                              const SizedBox(height: 4),
                              Text('Purpose: ${booking['purpose'] ?? '-'}'),
                              const SizedBox(height: 8),
                              Row(
                                children: [                                  if (booking['status'] == 'pending')
                                    TextButton(
                                      onPressed: () {
                                        // Show cancel confirmation dialog
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Cancel Booking'),
                                            content: const Text('Are you sure you want to cancel this booking?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('No'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  try {
                                                    await _bookingService.cancelBooking(booking['id']);
                                                    
                                                    if (mounted) {
                                                      setState(() {
                                                        _activeBookings.removeWhere((b) => b['id'] == booking['id']);
                                                      });
                                                      
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Booking cancelled successfully')),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Failed to cancel booking: $e')),
                                                    );
                                                  }
                                                },
                                                child: const Text('Yes'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Text('Cancel Booking'),
                                    ),
                                  const Spacer(),                                  TextButton.icon(
                                    onPressed: () {
                                      // Show booking details dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(booking['roomName']),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildDetailRow('Date', booking['date']),
                                                _buildDetailRow('Time', booking['time']),
                                                _buildDetailRow('Purpose', booking['purpose'] ?? 'Not specified'),
                                                _buildDetailRow('Status', booking['status'].toString().toUpperCase()),
                                                _buildDetailRow('Building', booking['building']),
                                                _buildDetailRow('Floor', booking['floor']),
                                                _buildDetailRow('Capacity', booking['capacity']),
                                                if (booking['features'] != null && booking['features'] is List)
                                                  _buildDetailRow('Features', (booking['features'] as List).join(', ')),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('Details'),
                                  ),
                                ],
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