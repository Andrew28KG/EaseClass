import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import '../../services/booking_service.dart';
import 'booking_detail_page.dart';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({Key? key}) : super(key: key);

  @override
  _BookingManagementPageState createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<BookingModel> _bookings = [];
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _bookingService.getAllBookings().first;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  List<BookingModel> _getFilteredBookings() {
    var filtered = _bookings;
    
    // Apply status filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((booking) => 
        booking.status.toLowerCase() == _selectedFilter.toLowerCase()
      ).toList();
    }
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((booking) =>
        (booking.roomDetails['name']?.toString().toLowerCase() ?? '').contains(searchTerm) ||
        (booking.userDetails?['name']?.toString().toLowerCase() ?? '').contains(searchTerm) ||
        booking.purpose.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    return filtered;
  }

  void _navigateToBookingDetail(BookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailPage(
          booking: booking,
          onBookingUpdated: _loadBookings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _getFilteredBookings();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search bookings...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Bookings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBookings.isEmpty
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
                              'No bookings found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                booking.roomDetails['name'] ?? 'Unknown Room',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text('Date: ${booking.date}'),
                                  Text('Time: ${booking.time}'),
                                  Text('Purpose: ${booking.purpose}'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(booking.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(booking.status),
                                          style: TextStyle(
                                            color: _getStatusColor(booking.status),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _navigateToBookingDetail(booking),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏱️ Pending';
      case 'approved':
        return '✅ Approved';
      case 'rejected':
        return '❌ Rejected';
      case 'completed':
        return '✓ Completed';
      case 'cancelled':
        return '❌ Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
} 