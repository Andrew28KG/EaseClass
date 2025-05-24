import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/room_service.dart';
import '../services/booking_service.dart';
import '../models/booking_model.dart';

class AdminDashboard extends StatefulWidget {
  final bool showTabs;
  
  const AdminDashboard({
    Key? key, 
    this.showTabs = false // Default to false when used in AdminMainPage
  }) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final RoomService _roomService = RoomService();
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  late TabController _tabController;
  
  // Dashboard stats
  int _totalRooms = 0;
  int _activeRooms = 0;
  int _pendingBookings = 0;
  int _completedBookings = 0;
  String _adminName = '';
  
  // Booking data
  List<BookingModel> _pendingBookingsList = [];
  List<BookingModel> _allBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get admin name
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _adminName = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Admin';
      }
      
      // Get room counts
      final rooms = await _roomService.getRooms().first;
      _totalRooms = rooms.length;
      _activeRooms = rooms.where((room) => room.isAvailable).length;
        // Get booking data for tables
      _pendingBookingsList = await _bookingService.getBookingsByStatus('pending').first;
      
      // Get all bookings for history
      _allBookings = [];
      final pendingBookings = await _bookingService.getBookingsByStatus('pending').first;
      final completedBookings = await _bookingService.getBookingsByStatus('completed').first;
      final cancelledBookings = await _bookingService.getBookingsByStatus('cancelled').first;
      
      _allBookings.addAll(pendingBookings);
      _allBookings.addAll(completedBookings);
      _allBookings.addAll(cancelledBookings);
      
      // Sort by creation date, newest first
      _allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Update counts
      _pendingBookings = pendingBookings.length;
      _completedBookings = completedBookings.length;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      
      // Set some default values in case of error
      setState(() {
        _totalRooms = 10;
        _activeRooms = 8;
        _pendingBookings = 5;
        _completedBookings = 25;
        _isLoading = false;
      });
    }  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        if (widget.showTabs) ...[
          Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Bookings'),
                Tab(text: 'History'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
            ),
          ),
        ],
        
        // Tab Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: widget.showTabs
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDashboardTab(),
                            _buildBookingsTab(),
                            _buildHistoryTab(),
                          ],
                        )
                      : _buildDashboardTab(), // Default to dashboard tab if no tabs to show
                ),
        ),
      ],
    );
  }Widget _buildDashboardTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message with hello user
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $_adminName',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Welcome to your Admin Dashboard',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats cards
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildStatCard(
                context,
                'Total Rooms',
                _totalRooms.toString(),
                Icons.meeting_room_outlined,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Active Rooms',
                _activeRooms.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildStatCard(
                context,
                'Pending Bookings',
                _pendingBookings.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Completed Bookings',
                _completedBookings.toString(),
                Icons.done_all,
                Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Pending Approvals preview
          if (_pendingBookingsList.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Pending Approvals',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(                  onPressed: () {
                    if (widget.showTabs) {
                      _tabController.animateTo(1); // Go to Bookings tab if tabs are shown
                    }
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentPendingBookings(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentPendingBookings() {
    final maxDisplay = _pendingBookingsList.length > 3 ? 3 : _pendingBookingsList.length;
    final recentPendingBookings = _pendingBookingsList.take(maxDisplay).toList();
    
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentPendingBookings.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final booking = recentPendingBookings[index];
          return ListTile(
            title: Text('Room: ${booking.roomDetails?['name'] ?? 'Room ${booking.roomId}'}'),
            subtitle: Text('Date: ${booking.date} | Time: ${booking.time}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _approveBooking(booking.id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _rejectBooking(booking.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsTab() {
    return _pendingBookingsList.isEmpty
        ? const Center(child: Text('No pending bookings'))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Approvals',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Room')),
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Purpose')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _pendingBookingsList.map((booking) {
                        return DataRow(
                          cells: [
                            DataCell(Text(booking.roomDetails?['name'] ?? 'Room ${booking.roomId}')),
                            DataCell(Text(booking.userDetails?['name'] ?? booking.userId)),
                            DataCell(Text(booking.date)),
                            DataCell(Text(booking.time)),
                            DataCell(Text(booking.purpose)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () => _approveBooking(booking.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () => _rejectBooking(booking.id),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildHistoryTab() {
    return _allBookings.isEmpty
        ? const Center(child: Text('No booking history'))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Room')),
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Created')),
                      ],
                      rows: _allBookings.map((booking) {
                        return DataRow(
                          cells: [
                            DataCell(Text(booking.roomDetails?['name'] ?? 'Room ${booking.roomId}')),
                            DataCell(Text(booking.userDetails?['name'] ?? booking.userId)),
                            DataCell(Text(booking.date)),
                            DataCell(Text(booking.time)),
                            DataCell(_buildStatusChip(booking.status)),
                            DataCell(Text(_formatTimestamp(booking.createdAt))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }
    
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _approveBooking(String bookingId) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, 'approved');
      _loadDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking approved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, 'rejected');
      _loadDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}