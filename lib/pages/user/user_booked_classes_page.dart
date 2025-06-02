import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import 'user_booking_detail_page.dart';
import 'user_booking_history_page.dart';

class UserBookedClassesPage extends StatefulWidget {
  const UserBookedClassesPage({Key? key}) : super(key: key);

  @override
  State<UserBookedClassesPage> createState() => _UserBookedClassesPageState();
}

class _UserBookedClassesPageState extends State<UserBookedClassesPage> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Approved',
    'Completed',
    'Cancelled',
    'This Week',
    'This Month',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final allBookings = await _bookingService.getUserBookings().first;
      if (mounted) {
        setState(() {
          _allBookings = allBookings
              .where((booking) =>
                  booking.roomDetails != null && // Ensure roomDetails is not null
                  booking.roomDetails!['name'] != null && // Check for class-specific fields
                  booking.roomDetails!['building'] != null &&
                  booking.roomDetails!['floor'] != null)
              .map((booking) => {
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
          }).toList();
          _allBookings.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case 'Pending':
        _filteredBookings = _allBookings.where((booking) => 
          booking['status'] == 'pending' || booking['status'] == 'process'
        ).toList();
        break;
      case 'Approved':
        _filteredBookings = _allBookings.where((booking) => 
          booking['status'] == 'approved'
        ).toList();
        break;
      case 'Completed':
        _filteredBookings = _allBookings.where((booking) => 
          booking['status'] == 'completed'
        ).toList();
        break;
      case 'Cancelled':
        _filteredBookings = _allBookings.where((booking) => 
          booking['status'] == 'cancelled' || booking['status'] == 'rejected'
        ).toList();
        break;
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
      default:
        _filteredBookings = List.from(_allBookings);
    }
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkGrey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
            _applyFilter();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.lightGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(booking['status']).withOpacity(0.3),
          width: 1,
        ),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.class_,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['roomName'] ?? 'Unknown Class',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Building ${booking['building']}, Floor ${booking['floor']}',
                          style: TextStyle(
                            color: AppColors.darkGrey.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(booking['status']),
                ],
              ),
              const SizedBox(height: 16),
              if ((booking['date'] ?? '').isNotEmpty && (booking['time'] ?? '').isNotEmpty) ...[
                _buildInfoRow(Icons.calendar_today, '${booking['date']} | ${booking['time']}'),
                const SizedBox(height: 8),
              ],
              if ((booking['purpose'] ?? '').isNotEmpty) ...[
                _buildInfoRow(Icons.description, booking['purpose'] ?? 'No purpose specified'),
                const SizedBox(height: 12),
              ] else ...[
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      color: AppColors.darkGrey.withOpacity(0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.darkGrey.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          ),
        ),
      ],
    );
  }

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

  void _navigateToBookingDetail(Map<String, dynamic> bookingData) {
    final bookingModel = BookingModel(
      id: bookingData['id'] ?? '',
      userId: bookingData['userId'] ?? '',
      roomId: bookingData['roomId'] ?? '',
      date: bookingData['date'] ?? '',
      time: bookingData['time'] ?? '',
      purpose: bookingData['purpose'] ?? '',
      status: bookingData['status'] ?? 'pending',
      createdAt: bookingData['createdAt'] is DateTime 
          ? Timestamp.fromDate(bookingData['createdAt'] as DateTime)
          : Timestamp.now(),
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
        builder: (context) => UserBookingDetailPage(
          booking: bookingModel,
          onBookingUpdated: _loadBookings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: Column(
          children: [
            // Filter dropdown
            Container(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: InputDecoration(
                  labelText: 'Filter by Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: _filterOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
              ),
            ),
            // Bookings list
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<BookingModel>>(
                    stream: _getFilteredBookings(),
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
                          child: Text('No bookings found'),
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return _buildBookingCard(booking.toMap());
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<BookingModel>> _getFilteredBookings() {
    return Stream.value(_filteredBookings.map((booking) {
      // Convert DateTime to Timestamp
      if (booking['createdAt'] is DateTime) {
        booking['createdAt'] = Timestamp.fromDate(booking['createdAt'] as DateTime);
      }
      return BookingModel.fromMap(booking);
    }).toList());
  }
}