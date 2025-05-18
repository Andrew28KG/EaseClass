import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart'; // Import navigation helper
import '../theme/app_colors.dart'; // Import app colors
import '../services/firestore_service.dart'; // Import Firestore service
import '../models/booking_model.dart'; // Import Booking model
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Firebase services
  final FirestoreService _firestoreService = FirestoreService();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load booking data
    _loadBookings();
  }
  
  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user bookings from Firestore
      final bookings = await _firestoreService.getUserBookings();
      
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Active Bookings',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Past Bookings',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // Active Bookings Tab (Pending and Upcoming)
          _buildBookingsList(context, isActive: true),
          
          // Past Bookings Tab (Completed)
          _buildBookingsList(context, isActive: false),
        ],
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, {required bool isActive}) {
    // Filter bookings based on active or past status
    final List<BookingModel> filteredBookings = _bookings.where((booking) {
      return isActive ? booking.isActive : booking.isCompleted;
    }).toList();
      if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.pending_actions : Icons.history,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active bookings' : 'No past bookings',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: filteredBookings.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              NavigationHelper.navigateToProgressDetail(
                context,
                {
                  'bookingId': booking.id,
                  'roomId': booking.roomId,
                  'date': booking.date,
                  'time': booking.time,
                  'status': booking.status,
                  'purpose': booking.purpose,
                  'roomDetails': booking.roomDetails,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getStatusColor(booking.status),
                    child: Icon(
                      _getStatusIcon(booking.status),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Room ${booking.roomId}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Only show status label for past bookings (Completed)
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(booking.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  booking.status.capitalize(),
                                  style: TextStyle(
                                    // Use a darker version of the color for better contrast
                                    color: _getStatusColorWithBetterContrast(booking.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(booking.roomDetails != null ? 
                              'Building ${booking.roomDetails!['building']} - Floor ${booking.roomDetails!['floor']}' : 
                              'Room details unavailable'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(booking.date),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(booking.time),
                          ],
                        ),
                        if (booking.status == 'completed')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                booking.rating != null
                                  ? Text('Rating: ${booking.rating}')
                                  : TextButton(
                                      onPressed: () {
                                        // Navigate to rating page
                                        NavigationHelper.navigateToRating(
                                          context,
                                          {
                                            'bookingId': booking.id,
                                            'roomId': booking.roomId,
                                          },
                                        );
                                      },
                                      child: const Text('Rate this booking'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                              ],
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'upcoming':
        return Icons.event_available;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColorWithBetterContrast(String status) {
    final baseColor = _getStatusColor(status);
    // Return a darker version of the color for better contrast on light backgrounds
    return baseColor.withOpacity(0.8);
  }
}

extension StringExtension on String {
  String capitalize() {
    return this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : this;
  }
} 