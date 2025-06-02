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

  @override
  void initState() {
    super.initState();
  }

  // Navigate to booking detail page for admin
  void _navigateToBookingDetail(Map<String, dynamic> bookingData) {
    // Convert booking data to BookingModel
    final bookingModel = BookingModel(
      id: bookingData['id'] ?? '',
      userId: bookingData['userId'] ?? '',
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
            setState(() {}); // Refresh the page
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
      children: [
          // Removed Filter dropdown as requested
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   child: DropdownButtonFormField<String>(
          //     value: _selectedFilter,
          //     decoration: InputDecoration(
          //       labelText: 'Filter by Status',
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     ),
          //     items: _filterOptions.map((String value) {
          //       return DropdownMenuItem<String>(
          //         value: value,
          //         child: Text(value),
          //       );
          //     }).toList(),
          //     onChanged: (String? newValue) {
          //       if (newValue != null) {
          //         setState(() {
          //           _selectedFilter = newValue;
          //         });
          //       }
          //     },
          //   ),
          // ),
          // Bookings list - now only shows pending approvals
        Expanded(
          child: StreamBuilder<List<BookingModel>>(
              // Directly stream pending bookings
              stream: _bookingService.getBookingsByStatus('pending'),
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
                      'roomName': booking.roomDetails?['name'] ?? 'Class ${booking.roomId}',
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
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToBookingDetail(booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking['roomName'] ?? 'Class ${booking['roomId']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(booking['status']),
                      style: TextStyle(
                        color: _getStatusColor(booking['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${booking['date']}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Time: ${_formatTimeWithDuration(booking['time'], booking['duration'] ?? 1)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Purpose: ${booking['purpose']}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Booked by: ${booking['userName']}',
                style: const TextStyle(fontSize: 14),
              ),
              if (booking['adminResponseReason'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Admin Response: ${booking['adminResponseReason']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
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
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper to format time with duration (copied from user booking detail page)
  String _formatTimeWithDuration(String time, int duration) {
    final timeParts = time.split(' ');
    final timeValue = timeParts[0];
    final period = timeParts[1];
    
    // Parse the time
    final timeComponents = timeValue.split(':');
    final hour = int.parse(timeComponents[0]);
    final minute = int.parse(timeComponents[1]);
    
    // Calculate end time
    final startTime = DateTime(2024, 1, 1, hour, minute);
    final endTime = startTime.add(Duration(hours: duration));
    
    // Format end time
    final endHour = endTime.hour;
    final endMinute = endTime.minute;
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final formattedEndHour = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
    
    return '$time - ${formattedEndHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} $endPeriod';
  }
}
