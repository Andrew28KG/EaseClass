import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import '../admin/booking_detail_page.dart';
import 'user_history_booking_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserBookingHistoryPage extends StatefulWidget {
  const UserBookingHistoryPage({Key? key}) : super(key: key);

  @override
  State<UserBookingHistoryPage> createState() => _UserBookingHistoryPageState();
}

class _UserBookingHistoryPageState extends State<UserBookingHistoryPage> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  String _selectedFilter = 'All';
  @override
  void initState() {
    super.initState();
    _loadCompletedBookings();
  }

  Future<void> _loadCompletedBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get completed and cancelled bookings for this tab
      final completedBookings = await _bookingService.getBookingsByStatus('completed').first;
      final cancelledBookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).where('status', isEqualTo: 'cancelled').get();
      // Fetch rejected bookings for the current user
      final rejectedBookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).where('status', isEqualTo: 'rejected').get();

      // Combine and map the results
      final cancelledBookings = cancelledBookingsSnapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
      final rejectedBookings = rejectedBookingsSnapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
      final allHistoryBookings = [...completedBookings, ...cancelledBookings, ...rejectedBookings];

      if (mounted) {
        setState(() {
          // Convert BookingModel objects to maps for the _allBookings list
          _allBookings = allHistoryBookings
              .where((booking) =>
                  booking.roomDetails != null && // Ensure roomDetails is not null
                  booking.roomDetails['name'] != null && // Check for class-specific fields
                  booking.roomDetails['building'] != null &&
                  booking.roomDetails['floor'] != null)
              .map((booking) => booking.toMap())
              .toList();
          
          // Sort by date, most recent first
          _allBookings.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading completed bookings: $e');
      // Use dummy data in case of error
      setState(() {
        _allBookings = [
          {
            'id': '1',
            'userName': 'John Doe',
            'roomName': 'Room A101',
            'building': 'A',
            'floor': '1',
            'capacity': 30,
            'features': ['Projector', 'Whiteboard', 'AC'],
            'date': '2025-01-15',
            'time': '09:00 - 11:00',
            'purpose': 'Programming Class',
            'status': 'completed',
            'createdAt': DateTime(2025, 1, 15),
          },
          {
            'id': '2',
            'userName': 'Jane Smith',
            'roomName': 'Room B202',
            'building': 'B',
            'floor': '2',
            'capacity': 20,
            'features': ['Whiteboard', 'AC'],
            'date': '2025-01-10',
            'time': '14:00 - 16:00',
            'purpose': 'Team Meeting',
            'status': 'completed',
            'createdAt': DateTime(2025, 1, 10),
          },
          {
            'id': '3',
            'userName': 'Mike Johnson',
            'roomName': 'Room C301',
            'building': 'C',
            'floor': '3',
            'capacity': 15,
            'features': ['Projector', 'AC'],
            'date': '2024-12-20',
            'time': '10:00 - 12:00',
            'purpose': 'Workshop',
            'status': 'completed',
            'createdAt': DateTime(2024, 12, 20),
          },
        ];
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case 'This Week':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        _filteredBookings = _allBookings.where((booking) {
          final bookingDate = booking['createdAt'] as DateTime;
          return bookingDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                 bookingDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
        break;
      case 'This Month':
        final now = DateTime.now();
        _filteredBookings = _allBookings.where((booking) {
          final bookingDate = booking['createdAt'] as DateTime;
          return bookingDate.year == now.year && bookingDate.month == now.month;
        }).toList();
        break;
      case 'Last Month':
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1);
        _filteredBookings = _allBookings.where((booking) {
          final bookingDate = booking['createdAt'] as DateTime;
          return bookingDate.year == lastMonth.year && bookingDate.month == lastMonth.month;
        }).toList();
        break;
      case 'Last 3 Months':
        final now = DateTime.now();
        final threeMonthsAgo = DateTime(now.year, now.month - 3);
        _filteredBookings = _allBookings.where((booking) {
          final bookingDate = booking['createdAt'] as DateTime;
          return bookingDate.isAfter(threeMonthsAgo.subtract(const Duration(days: 1)));
        }).toList();
        break;
      default: // 'All'
        _filteredBookings = List.from(_allBookings);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Content section only, no filter bar
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadCompletedBookings,
                  child: _filteredBookings.isEmpty
                      ? const Center(
                          child: Text(
                            'No completed or cancelled bookings found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final hasRating = booking['rating'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToBookingDetail(booking),
        borderRadius: BorderRadius.circular(12),
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
                      booking['roomName'] ?? 'Room',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Building ${booking['building']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.stairs, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Floor ${booking['floor']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    booking['date'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    booking['time'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (status == 'completed') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      hasRating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: hasRating ? Colors.amber : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasRating ? 'Rated: ${booking['rating']}' : 'Not rated yet',
                      style: TextStyle(
                        color: hasRating ? Colors.amber : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: hasRating ? FontWeight.bold : FontWeight.normal,
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

  // Helper function for info rows (copy from UserBookedRoomsPage)
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.darkGrey.withOpacity(0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.darkGrey.withOpacity(0.8),
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis, // Add overflow handling
          ),
        ),
      ],
    );
  }

  // Helper function for status chip (copy from UserBookedRoomsPage)
  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

   // Helper function for status text (copy from UserBookedRoomsPage)
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'process':
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

  // Helper function for status color (copy from UserBookedRoomsPage)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'process':
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

  void _navigateToBookingDetail(Map<String, dynamic> booking) {
    // Convert booking data to BookingModel
    final bookingModel = BookingModel(
      id: booking['id'] ?? '',
      roomId: booking['roomId'] ?? '',
      userId: booking['userId'] ?? '',
      date: booking['date'] ?? '',
      time: booking['time'] ?? '',
      purpose: booking['purpose'] ?? '',
      status: booking['status'] ?? '',
      createdAt: booking['createdAt'] is Timestamp 
          ? booking['createdAt'] 
          : Timestamp.fromDate(booking['createdAt'] ?? DateTime.now()),
      rating: booking['rating']?.toDouble(),
      feedback: booking['feedback'],
      roomDetails: {
        'name': booking['roomName'],
        'building': booking['building'],
        'floor': booking['floor'],
        'capacity': booking['capacity'],
        'features': booking['features'],
      },
      userDetails: {
        'name': booking['userName'],
      },
      duration: booking['duration'] ?? 1, // Pass duration
      extraItemsNotes: booking['extraItemsNotes'], // Pass extraItemsNotes
      adminResponseReason: booking['adminResponseReason'], // Pass adminResponseReason
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserHistoryBookingDetailPage(booking: bookingModel), // Navigate to the new page
      ),
    );
  }
}
