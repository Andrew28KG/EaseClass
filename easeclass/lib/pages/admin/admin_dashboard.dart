import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/room_service.dart';
import '../../services/booking_service.dart';
import '../../services/database_initializer.dart';
import '../../models/booking_model.dart';
import 'simplified_dashboard_components.dart';
import 'booking_detail_page.dart';

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
  final DatabaseInitializer _databaseInitializer = DatabaseInitializer();
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
  
  // New data for enhanced dashboard
  List<Map<String, dynamic>> _recentReviews = [];
  List<Map<String, dynamic>> _topBookedClasses = [];
  List<Map<String, dynamic>> _topBookedRooms = [];

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

      // Load new data
      _recentReviews = await _bookingService.getRecentReviews(limit: 5);
      _topBookedClasses = await _bookingService.getTopBookedClasses(limit: 5);
      _topBookedRooms = await _bookingService.getTopBookedRooms(limit: 5);

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
        // Custom Gradient Header (like user header)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark ?? Theme.of(context).primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'EaseClass',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Book rooms with ease',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        // Tab Bar
        if (widget.showTabs) ...[          Material(
            elevation: 2,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    width: 2,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.dashboard_rounded),
                    text: 'Dashboard',
                    iconMargin: const EdgeInsets.only(bottom: 4),
                  ),
                  Tab(
                    icon: const Icon(Icons.pending_actions),
                    text: 'Bookings',
                    iconMargin: const EdgeInsets.only(bottom: 4),
                  ),
                  Tab(
                    icon: const Icon(Icons.history),
                    text: 'History',
                    iconMargin: const EdgeInsets.only(bottom: 4),
                  ),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicatorWeight: 3,
                indicatorColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
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
  }
    Widget _buildDashboardTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message with hello user
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $_adminName',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome to your Admin Dashboard',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
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
          _buildSectionHeader('Overview'),
          const SizedBox(height: 8),
          
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
            const SizedBox(height: 24),          // Recent Pending Approvals preview
          _buildRecentPendingBookings(),
            const SizedBox(height: 24),
          // Recent Reviews section
          _buildRecentReviews(),
          
          const SizedBox(height: 24),
            // Top Booked Classes section
          if (_topBookedClasses.isNotEmpty) ...[
            _buildTopBookedClasses(),
          ],
          
          const SizedBox(height: 24),
            // Top Booked Rooms section
          if (_topBookedRooms.isNotEmpty) ...[
            _buildTopBookedRooms(),
          ],
        ],
      ),
    );
  }
  Widget _buildRecentPendingBookings() {
    final maxDisplay = _pendingBookingsList.length > 3 ? 3 : _pendingBookingsList.length;
    final recentPendingBookings = _pendingBookingsList.take(maxDisplay).toList();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),                Text(
                  'Approvals',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (recentPendingBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No pending approvals')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentPendingBookings.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final booking = recentPendingBookings[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                  title: Text(
                    booking.roomDetails?['name'] ?? 'Room ${booking.roomId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(booking.date),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(booking.time),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.userDetails?['name'] ?? booking.userId,
                              style: TextStyle(color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,                  trailing: buildApprovalButtons(
                    onApprove: () => _approveBooking(booking.id),
                    onReject: () => _rejectBooking(booking.id),
                  ),
                );
              },
            ),
          if (recentPendingBookings.length < _pendingBookingsList.length)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.list_alt),
                label: Text('View all ${_pendingBookingsList.length} pending bookings'),
                onPressed: () {
                  if (widget.showTabs) {
                    _tabController.animateTo(1);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildRecentReviews() {
    final maxDisplay = _recentReviews.length > 3 ? 3 : _recentReviews.length;
    final displayReviews = _recentReviews.take(maxDisplay).toList();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Card header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.rate_review, color: Colors.blue.shade800, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reviews',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          
          // Card content
          if (displayReviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No reviews yet'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayReviews.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final review = displayReviews[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                  title: Text(
                    review['room']?['name'] ?? 'Unknown Room',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),                  subtitle: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${review['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),                  trailing: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      review['user']?['name'] ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  Widget _buildTopBookedClasses() {
    if (_topBookedClasses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No class booking data')),
        ),
      );
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.class_outlined, color: Colors.green.shade800, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Popular Classes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topBookedClasses.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final classData = _topBookedClasses[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.green)),
                ),                title: Text(
                  classData['name'] ?? 'Unknown Class',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Building: ${classData['building'] ?? 'N/A'}, Floor: ${classData['floor'] ?? 'N/A'}',
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  constraints: const BoxConstraints(maxWidth: 90),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${classData['bookingCount'] ?? 0}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }  Widget _buildTopBookedRooms() {
    if (_topBookedRooms.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(30.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No room booking data available'),
              ],
            ),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.purple.shade800, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Popular Rooms',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topBookedRooms.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 70,
              endIndent: 16,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final roomData = _topBookedRooms[index];
              final isTopRoom = index == 0;
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: isTopRoom ? Colors.purple : Colors.purple.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontWeight: isTopRoom ? FontWeight.bold : FontWeight.normal,
                          fontSize: isTopRoom ? 16 : 14,
                          color: isTopRoom ? Colors.white : Colors.purple,
                        ),
                      ),
                      if (isTopRoom)
                        const Icon(Icons.emoji_events, size: 12, color: Colors.amber)
                    ],
                  ),                ),
                title: Text(
                  roomData['name'] ?? 'Unknown Room',
                  style: TextStyle(
                    fontWeight: isTopRoom ? FontWeight.bold : FontWeight.normal,
                    fontSize: isTopRoom ? 16 : 14,
                  ),                ),
                subtitle: Text(
                  'Building: ${roomData['building'] ?? 'N/A'}',
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: false,                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  constraints: const BoxConstraints(maxWidth: 60),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    '${roomData['bookingCount'] ?? 0}',
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
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
                _buildSectionHeader('Pending Bookings'),
                const SizedBox(height: 8),
                Text(
                  'Tap on a booking card to view details and approve/reject',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingBookingsList.length,
                  itemBuilder: (context, index) {
                    final booking = _pendingBookingsList[index];
                    return _buildBookingCard(booking);
                  },
                ),
              ],
            ),
          );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailPage(
                booking: booking,
                onBookingUpdated: () {
                  // Refresh the dashboard data when booking is updated
                  _loadDashboardData();
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with room name and status
              Row(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_actions, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'PENDING',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Booking details
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            booking.userDetails?['name'] ?? booking.userId,
                            style: TextStyle(color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Building ${booking.roomDetails?['building'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          booking.date,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          booking.time,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Purpose
              Row(
                children: [
                  Icon(Icons.description, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.purpose,
                      style: TextStyle(color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Action hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],            ),
            ],
          ),
        ),
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
              children: [                _buildSectionHeader('Booking History'),
                const SizedBox(height: 8),
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
                      ],                      rows: _allBookings.map((booking) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                constraints: const BoxConstraints(maxWidth: 150),
                                child: Text(
                                  booking.roomDetails?['name'] ?? 'Room ${booking.roomId}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              )
                            ),
                            DataCell(
                              Container(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  booking.userDetails?['name'] ?? booking.userId,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              )
                            ),
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
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
        ],      ),
    );
  }
}