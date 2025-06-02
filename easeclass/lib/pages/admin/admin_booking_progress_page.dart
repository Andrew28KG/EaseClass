import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import 'booking_detail_page.dart';

class AdminBookingProgressPage extends StatefulWidget {
  const AdminBookingProgressPage({Key? key}) : super(key: key);

  @override
  State<AdminBookingProgressPage> createState() => _AdminBookingProgressPageState();
}

class _AdminBookingProgressPageState extends State<AdminBookingProgressPage> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<BookingModel> _approvedBookings = [];

  @override
  void initState() {
    super.initState();
    _loadApprovedBookings();
  }

  Future<void> _loadApprovedBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookings = await _bookingService.getBookingsByStatus('approved').first;
      if (mounted) {
        setState(() {
          _approvedBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading approved bookings: $e');
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
          : _approvedBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No approved bookings',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Approved bookings will appear here',
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
                  itemCount: _approvedBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _approvedBookings[index];
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
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
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
            _loadApprovedBookings();
          },
        ),
      ),
    );
  }
}
