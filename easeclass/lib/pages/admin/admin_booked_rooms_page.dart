import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import 'booking_detail_page.dart';

class AdminBookedRoomsPage extends StatefulWidget {
  const AdminBookedRoomsPage({Key? key}) : super(key: key);

  @override
  State<AdminBookedRoomsPage> createState() => _AdminBookedRoomsPageState();
}

class _AdminBookedRoomsPageState extends State<AdminBookedRoomsPage> {
  final BookingService _bookingService = BookingService();
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Approved',
    'Completed',
    'Cancelled',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
  }

  // Navigate to booking detail page for admin
  void _navigateToBookingDetail(Map<String, dynamic> bookingData) {
    // Convert booking data to BookingModel
    final bookingModel = BookingModel(
      id: bookingData['id'] ?? '',
      userId: bookingData['userId'] ?? '', // Included userId
      roomId: bookingData['roomId'] ?? '',
      date: bookingData['date'] ?? '',
      time: bookingData['time'] ?? '',
      purpose: bookingData['purpose'] ?? '',
      status: bookingData['status'] ?? '',
      createdAt: Timestamp.fromDate(bookingData['createdAt'] ?? DateTime.now()),
      roomDetails: {
        'name': bookingData['roomName'],
        'building': bookingData['building'],
        'floor': bookingData['floor'],
        'capacity': bookingData['capacity'],
        'features': bookingData['features'],
      },
      userDetails: {
        'name': bookingData['userName'],
      },
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailPage(
          booking: bookingModel,
          onBookingUpdated: () {
            // No need to manually refresh, StreamBuilder will handle it
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<BookingModel>>(
            stream: _getFilteredBookings(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading bookings: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookings = snapshot.data ?? [];

              if (bookings.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No bookings found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final bookingMap = { 
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
                    'userId': booking.userId,
                    'adminResponseReason': booking.adminResponseReason,
                  };
                  return _buildBookingCard(bookingMap);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<List<BookingModel>> _getFilteredBookings() {
    switch (_selectedFilter) {
      case 'Pending':
        return _bookingService.getBookingsByStatus('pending');
      case 'Approved':
        return _bookingService.getBookingsByStatus('approved');
      case 'Completed':
        return _bookingService.getBookingsByStatus('completed');
      case 'Cancelled':
        return _bookingService.getBookingsByStatus('cancelled');
      case 'Rejected':
        return _bookingService.getBookingsByStatus('rejected');
      default:
        return _bookingService.getAllBookings();
    }
  }

  String _getStatusChip(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏱️ Pending';
      case 'approved':
        return '✅ Approved';
      case 'completed':
        return '✓ Completed';
      case 'cancelled':
        return '❌ Cancelled';
      case 'rejected':
        return '❌ Rejected';
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
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    // This is the existing card widget for displaying booking information
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(booking['status']).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
           _navigateToBookingDetail(booking); // Navigate to detail page on tap
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking['roomName'] ?? 'Unknown Room',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _getStatusChip(booking['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(booking['status']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'By: ${booking['userName'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${booking['date'] ?? '-'} | ${booking['time'] ?? '-'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Building ${booking['building'] ?? '-'}, Floor ${booking['floor'] ?? '-'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
               const SizedBox(height: 8),
               Row(
                 children: [
                   const Icon(Icons.meeting_room_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${booking['capacity'] ?? 'N/A'}',
                       style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                 ],
               ),
               if (booking['features'] != null && booking['features'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                   Row(
                    children: [
                      const Icon(Icons.extension, size: 16, color: Colors.grey),
                       const SizedBox(width: 4),
                       Expanded(
                         child: Text(
                           'Features: ${booking['features'].join(', ')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                         ),
                       ),
                    ],
                  ),
               ],
               const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.notes, size: 16, color: Colors.grey),
                     const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                         'Purpose: ${booking['purpose'] ?? 'N/A'}',
                          style: TextStyle(
                           fontSize: 14,
                            color: Colors.grey.shade700,
                           ),
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
