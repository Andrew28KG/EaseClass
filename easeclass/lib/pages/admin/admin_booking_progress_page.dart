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
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Active Today',
    'In Progress',
    'This Week',
    'This Month',
  ];

  @override
  void initState() {
    super.initState();
    _loadOngoingBookings();
  }  Future<void> _loadOngoingBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get on-going bookings (approved bookings that are currently active)
      final ongoingBookings = await _bookingService.getBookingsByStatus('ongoing').first;
      final approvedBookings = await _bookingService.getBookingsByStatus('approved').first;

      if (mounted) {
        setState(() {
          _allBookings = [
            ...ongoingBookings.map((booking) => _mapBookingToDisplayData(booking)),
            ...approvedBookings.map((booking) => _mapBookingToDisplayData(booking)),
          ];
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ongoing bookings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _mapBookingToDisplayData(BookingModel booking) {
    return {
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
    };
  }
  void _applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = '${today.day}/${today.month}/${today.year}';
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    setState(() {
      switch (_selectedFilter) {
        case 'All':
          _filteredBookings = List.from(_allBookings);
          break;
        case 'Active Today':
          _filteredBookings = _allBookings.where((booking) {
            return booking['date'] == todayStr;
          }).toList();
          break;
        case 'In Progress':
          _filteredBookings = _allBookings.where((booking) {
            return booking['status'] == 'ongoing' || booking['status'] == 'approved';
          }).toList();
          break;
        case 'This Week':
          _filteredBookings = _allBookings.where((booking) {
            final bookingDate = _parseDate(booking['date']);
            return bookingDate != null && 
                   bookingDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
                   bookingDate.isBefore(endOfWeek.add(const Duration(days: 1)));
          }).toList();
          break;
        case 'This Month':
          _filteredBookings = _allBookings.where((booking) {
            final bookingDate = _parseDate(booking['date']);
            return bookingDate != null && 
                   bookingDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
                   bookingDate.isBefore(endOfMonth.add(const Duration(days: 1)));
          }).toList();
          break;
      }
    });
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      print('Error parsing date: $dateStr');
    }
    return null;
  }
  String _formatDate(String dateStr) {
    return dateStr; // Already in dd/mm/yyyy format
  }

  String _formatTime(String timeStr) {
    return timeStr; // Already in HH:MM - HH:MM format
  }

  String _getProgressStatus(Map<String, dynamic> booking) {
    final status = booking['status'] as String;
    final dateStr = booking['date'] as String;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = _parseDate(dateStr);

    if (bookingDate == null) return 'Unknown';

    if (status == 'ongoing') {
      return 'Active Now';
    } else if (status == 'approved') {
      if (bookingDate.isAfter(today)) {
        return 'Upcoming';
      } else if (bookingDate.isAtSameMomentAs(today)) {
        return 'Active Today';
      } else {
        return 'Completed';
      }
    }
    return status.toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active Now':
        return Colors.green;
      case 'Upcoming':
        return AppColors.secondary;
      case 'Completed':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredBookings.isEmpty
              ? const Center(child: Text('No on-going bookings found'))
              : ListView.builder(
                  itemCount: _filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _filteredBookings[index];
                    final progressStatus = _getProgressStatus(booking);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _navigateToBookingDetail(booking),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      booking['roomName'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(progressStatus).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getStatusColor(progressStatus),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      progressStatus,
                                      style: TextStyle(
                                        color: _getStatusColor(progressStatus),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Location Info
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${booking['building']} - Floor ${booking['floor']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              
                              // User Info
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking['userName'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Date and Time
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),                                                  Text(
                                            _formatDate(booking['date']),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Time',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatTime(booking['time']),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
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
                ),
    );
  }
  void _navigateToBookingDetail(Map<String, dynamic> booking) {
    // Convert the booking data to BookingModel for the detail page
    final bookingModel = BookingModel(
      id: booking['id'],
      userId: '', // We don't have userId in the display data
      roomId: booking['roomId'] ?? '',
      date: booking['date'],
      time: booking['time'],
      purpose: booking['purpose'],
      status: booking['status'],
      createdAt: Timestamp.fromDate(booking['createdAt']),
      rating: null,
      feedback: null,
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
        builder: (context) => BookingDetailPage(
          booking: bookingModel,
          onBookingUpdated: () {
            // Refresh the bookings list when booking is updated
            _loadOngoingBookings();
          },
        ),
      ),
    );
  }
}
