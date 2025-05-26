import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import 'booking_detail_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
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
                'Error loading bookings: \\${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
          final bookings = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return BookingModel(
              id: doc.id,
              roomId: data['roomId'] ?? '',
              userId: data['userId'] ?? '',
              date: data['date'] ?? '',
              time: data['time'] ?? '',
              status: data['status'] ?? '',
              purpose: data['purpose'] ?? '',
              createdAt: data['createdAt'] != null 
                  ? data['createdAt'] as Timestamp
                  : Timestamp.now(),
              roomDetails: data['roomDetails'],
              userDetails: data['userDetails'],
            );
          }).toList();

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

  Stream<QuerySnapshot> _getFilteredBookingsStream() {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('status', whereIn: ['completed', 'rejected']);

    // Apply date filters
    if (selectedFilter == 'This Week') {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
      
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek));
    } else if (selectedFilter == 'This Month') {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59);
      
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));
    } else if (selectedFilter == 'Completed') {
      query = query.where('status', isEqualTo: 'completed');
    } else if (selectedFilter == 'Rejected') {
      query = query.where('status', isEqualTo: 'rejected');
    }

    return query.orderBy('createdAt', descending: true).snapshots();
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
    final userName = booking.userDetails?['name'] ?? 'Unknown User';

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
                    booking.date,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    booking.time,
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
              
              // Submission Date
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'Processed: ${_formatDate(booking.createdAt.toDate())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
