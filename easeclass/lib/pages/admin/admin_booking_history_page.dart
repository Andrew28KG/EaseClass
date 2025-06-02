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
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<BookingModel> _historyBookings = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryBookings();
  }

  Future<void> _loadHistoryBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final completedBookings = await _bookingService.getBookingsByStatus('completed').first;
      final rejectedBookings = await _bookingService.getBookingsByStatus('rejected').first;
      
      if (mounted) {
        setState(() {
          _historyBookings = [...completedBookings, ...rejectedBookings];
          // Sort by date, most recent first
          _historyBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading history bookings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyBookings.isEmpty
              ? Center(
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
                        'No booking history',
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _historyBookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
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
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: booking.status == 'completed'
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      booking.status == 'completed'
                                          ? Icons.check_circle_outline
                                          : Icons.cancel_outlined,
                                      color: booking.status == 'completed'
                                          ? Colors.blue
                                          : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.roomDetails?['name'] ?? 'Unknown Class',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Booked by: ${booking.userDetails?['name'] ?? 'Unknown User'}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    Icons.calendar_today,
                                    booking.date,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildInfoChip(
                                    Icons.access_time,
                                    booking.time,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.description_outlined,
                                      booking.purpose,
                                      isExpandable: true,
                                    ),
                                  ),
                                ],
                              ),
                              if (booking.status == 'completed' && booking.rating != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rating: ${booking.rating}',
                                        style: TextStyle(
                                          color: Colors.amber[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {bool isExpandable = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              overflow: isExpandable ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBookingDetail(BookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailPage(
          booking: booking,
          onBookingUpdated: () {
            // Refresh the bookings list when booking is updated
            _loadHistoryBookings();
          },
        ),
      ),
    );
  }
}
