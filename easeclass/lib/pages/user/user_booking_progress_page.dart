import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/navigation_helper.dart';

class UserBookingProgressPage extends StatefulWidget {
  const UserBookingProgressPage({Key? key}) : super(key: key);

  @override
  State<UserBookingProgressPage> createState() => _UserBookingProgressPageState();
}

class _UserBookingProgressPageState extends State<UserBookingProgressPage> {
  final BookingService _bookingService = BookingService();
  List<BookingModel> _progressBookings = [];
  bool _isLoading = true;
  String? _selectedFilter;

  final List<String> _filterOptions = [
    'All',
    'Just Started',
    'In Progress',
    'Almost Complete',
  ];

  @override
  void initState() {
    super.initState();
    _loadProgressBookings();
  }  Future<void> _loadProgressBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingsStream = _bookingService.getUserBookings();
      final bookings = await bookingsStream.first;
      setState(() {
        // Filter for on-going bookings (new status system)
        _progressBookings = bookings.where((booking) => 
          booking.status == 'on-going' || 
          booking.status == 'ongoing' ||
          booking.status == 'approved' // temporary backward compatibility
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<BookingModel> _getFilteredBookings() {
    if (_selectedFilter == null || _selectedFilter == 'All') {
      return _progressBookings;
    }
    
    // Add more sophisticated filtering logic here based on progress status
    return _progressBookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
                              _selectedFilter = selected ? filter : null;
                            });
                          },
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
          
          // Progress Bookings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProgressBookings,
                    child: _buildProgressList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressList() {
    final filteredBookings = _getFilteredBookings();
    
    if (filteredBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No bookings in progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your approved bookings will appear here\nonce they\'re marked as on-going',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return _buildProgressCard(booking);
      },
    );
  }

  Widget _buildProgressCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          NavigationHelper.navigateToProgressDetail(context, {
            'booking': booking.toMap(),
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with room name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.roomDetails?['name'] ?? 'Room ${booking.roomId}',
                      style: const TextStyle(
                        fontSize: 18,
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
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: Text(
                      'ON-GOING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Location and time info
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.roomDetails != null 
                        ? 'Building ${booking.roomDetails!['building']}, Floor ${booking.roomDetails!['floor']}'
                        : 'Location not available',
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
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.date} • ${booking.time}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              if (booking.purpose.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.purpose,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Progress indicator and action buttons
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: 0.6, // This could be calculated based on time elapsed
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'In progress...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      NavigationHelper.navigateToProgressDetail(context, {
                        'booking': booking.toMap(),
                      });
                    },
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
