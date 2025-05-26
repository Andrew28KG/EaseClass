import 'package:flutter/material.dart';
import '../../utils/navigation_helper.dart'; // Import navigation helper
import '../../theme/app_colors.dart'; // Import app colors
import '../../services/firestore_service.dart'; // Import Firestore service
import '../../models/booking_model.dart'; // Import Booking model

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
        title: const Text('Booking Progress'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.hourglass_empty),
              text: 'In Progress',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Completed',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())          : TabBarView(
        controller: _tabController,
        children: [
          // In Progress Tab (Pending and Upcoming with progress tracking)
          _buildProgressTrackingList(context),
          
          // Completed Bookings Tab
          _buildCompletedBookingsList(context),
        ],
      ),
    );
  }
  Widget _buildProgressTrackingList(BuildContext context) {
    // Filter bookings for in-progress (pending and upcoming)
    final List<BookingModel> inProgressBookings = _bookings.where((booking) {
      return booking.status.toLowerCase() == 'pending' || booking.status.toLowerCase() == 'upcoming';
    }).toList();
    
    if (inProgressBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings in progress',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your active bookings will appear here with progress tracking',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                NavigationHelper.navigateToAvailableRooms(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Book a Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: inProgressBookings.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final booking = inProgressBookings[index];
        return _buildProgressCard(booking, context);
      },
    );
  }

  Widget _buildCompletedBookingsList(BuildContext context) {
    // Filter bookings for completed status
    final List<BookingModel> completedBookings = _bookings.where((booking) {
      return booking.status.toLowerCase() == 'completed';
    }).toList();
    
    if (completedBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No completed bookings',
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
      itemCount: completedBookings.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final booking = completedBookings[index];
        return _buildCompletedBookingCard(booking, context);
      },
    );
  }

  Widget _buildProgressCard(BookingModel booking, BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(booking.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with room info and progress indicator
              Row(
                children: [
                  // Progress indicator
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(booking.status),
                          _getStatusColor(booking.status).withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(booking.status).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(booking.status),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Room info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${booking.roomId}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(booking.status).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(booking.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              // Progress timeline
              _buildProgressTimeline(booking.status),
              
              const SizedBox(height: 16),
              
              // Booking details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on,
                      'Location',
                      booking.roomDetails != null ? 
                        'Building ${booking.roomDetails!['building']}, Floor ${booking.roomDetails!['floor']}' : 
                        'Location details unavailable',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today,
                      'Date',
                      booking.date,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time,
                      'Time',
                      booking.time,
                    ),
                  ),
                ],
              ),
              
              if (booking.purpose.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailItem(
                  Icons.description,
                  'Purpose',
                  booking.purpose,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedBookingCard(BookingModel booking, BuildContext context) {
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking.status.capitalize(),
                            style: TextStyle(
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
  }

  Widget _buildProgressTimeline(String status) {
    final steps = [
      {'title': 'Booking Submitted', 'completed': true},
      {'title': 'Admin Review', 'completed': status != 'pending'},
      {'title': 'Confirmed', 'completed': status == 'upcoming' || status == 'completed'},
      {'title': 'Ready for Use', 'completed': status == 'completed'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;
        
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step['completed'] as bool
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                  child: Icon(
                    step['completed'] as bool
                        ? Icons.check
                        : Icons.circle_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 20,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontWeight: step['completed'] as bool
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: step['completed'] as bool
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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