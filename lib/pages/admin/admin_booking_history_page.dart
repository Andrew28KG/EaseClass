import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import 'booking_detail_page.dart';
import '../../services/booking_service.dart';

class AdminBookingHistoryPage extends StatefulWidget {
  const AdminBookingHistoryPage({Key? key}) : super(key: key);

  @override
  State<AdminBookingHistoryPage> createState() => _AdminBookingHistoryPageState();
}

class _AdminBookingHistoryPageState extends State<AdminBookingHistoryPage> {
  String selectedFilter = 'All';
  final List<String> filterOptions = [
    'All',
    'Completed',
    'Rejected',
    'This Week',
    'This Month',
  ];

  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<BookingModel>>(
        stream: _getFilteredBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading bookings: \${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Access the list of BookingModel directly from snapshot.data
          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No booking history found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed and rejected bookings will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking);
            },
          );
        },
      ),
    );
  }

  Stream<List<BookingModel>> _getFilteredBookingsStream() {
    // Use BookingService to get all bookings with user details
    Stream<List<BookingModel>> allBookingsStream = _bookingService.getAllBookings();

    // Apply filters to the stream
    return allBookingsStream.map((allBookings) {
      // Filter by status
      List<BookingModel> filteredByStatus = allBookings.where((booking) {
        if (selectedFilter == 'All') {
          return booking.status == 'completed' || booking.status == 'rejected';
        } else if (selectedFilter == 'Completed') {
          return booking.status == 'completed';
        } else if (selectedFilter == 'Rejected') {
          return booking.status == 'rejected';
        }
        return false; // Should not happen with defined filters
      }).toList();

    // Apply date filters
    if (selectedFilter == 'This Week') {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
      
        return filteredByStatus.where((booking) {
          final bookingDate = booking.createdAt.toDate();
          return bookingDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
                 bookingDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

    } else if (selectedFilter == 'This Month') {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59);
      
        return filteredByStatus.where((booking) {
          final bookingDate = booking.createdAt.toDate();
          return bookingDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
                 bookingDate.isBefore(endOfMonth.add(const Duration(days: 1)));
        }).toList();

      } else {
        // 'All', 'Completed', 'Rejected' filters without date constraints
        return filteredByStatus;
      }
    });
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

  Widget _buildBookingCard(BookingModel booking) {
    Color statusColor;
    IconData statusIcon;
    
    switch (booking.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    // Get room name and user name from details
    final roomName = booking.roomDetails?['name'] ?? 'Unknown Room';
    final userName = booking.userDetails?['displayName'] ?? booking.userDetails?['name'] ?? 'Unknown User';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailPage(booking: booking),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Booking Details
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${booking.date}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Time: ${_formatTimeWithDuration(booking.time, booking.duration ?? 1)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // User Details
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Purpose
              if (booking.purpose.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.purpose,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
