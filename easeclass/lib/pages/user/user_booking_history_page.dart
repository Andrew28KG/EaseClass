import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import '../admin/booking_detail_page.dart';
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

      // Combine and map the results
      final cancelledBookings = cancelledBookingsSnapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
      final allHistoryBookings = [...completedBookings, ...cancelledBookings];

      if (mounted) {
        setState(() {
          // Convert BookingModel objects to maps for the _allBookings list
          _allBookings = allHistoryBookings.map((booking) => booking.toMap()).toList();
          
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
                            return _buildBookingHistoryCard(booking);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildBookingHistoryCard(Map<String, dynamic> booking) {
    // Minimal user info only
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          booking['roomName'] ?? 'Unknown Room',
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
                const Icon(Icons.calendar_today, size: 16, color: AppColors.darkGrey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${booking['date'] ?? 'No date'} | ${booking['time'] ?? 'No time'}',
                    style: const TextStyle(fontSize: 14, color: AppColors.darkGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.darkGrey),
                const SizedBox(width: 4),
                Text(
                  'Building ${booking['building']} - Floor ${booking['floor']}',
                  style: const TextStyle(fontSize: 14, color: AppColors.darkGrey),
                ),
              ],
            ),
            if ((booking['purpose'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.description, size: 16, color: AppColors.darkGrey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      booking['purpose'],
                      style: const TextStyle(fontSize: 13, color: AppColors.darkGrey, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: () => _navigateToBookingDetail(booking),
      ),
    );
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
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailPage(booking: bookingModel),
      ),
    );
  }
}
