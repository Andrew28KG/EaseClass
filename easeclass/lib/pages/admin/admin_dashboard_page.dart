import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart'; // To get current user
import '../../models/user_model.dart'; // To use UserModel
import '../../models/booking_model.dart'; // To use BookingModel
import '../../models/class_model.dart'; // To use ClassModel
import '../../models/event_model.dart'; // To use EventModel
import '../../models/faq_model.dart'; // To use FAQModel
import '../../models/review_model.dart'; // To use ReviewModel

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Admin User Info
  UserModel? _adminUser;

  // Overview Counts
  int _totalUserCount = 0;
  int _totalClassCount = 0;
  int _totalBookingCount = 0;
  int _totalEventCount = 0;
  // Removed Approved/Ongoing Booking count as per user request
  // int _approvedOngoingBookingCount = 0;

  // Pending Bookings (list to show a few)
  List<BookingModel> _pendingBookings = [];

  // Recent Reviews (list to show a few)
  List<ReviewModel> _recentReviews = [];

  // Top Booked Class
  ClassModel? _topBookedClass;
  int _topBookedCount = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch Admin User Info
      final firebaseUser = _authService.getCurrentUser();
      if (firebaseUser != null) {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          _adminUser = UserModel.fromFirestore(userDoc);
        } else {
           // Handle case where user document does not exist (e.g., new admin login)
           // Optionally create a basic user document here or prompt admin to update profile
           print('Admin user document not found for UID: ${firebaseUser.uid}');
        }
      } else {
         print('No user is currently logged in.');
      }

      // Fetch Overview Counts
      final userSnapshot = await _firestore.collection('users').count().get();
      final classSnapshot = await _firestore.collection('classes').count().get();
      // Fetch count for Approved Bookings for the Total Bookings overview
      final approvedBookingSnapshot = await _firestore.collection('bookings').where('status', isEqualTo: 'approved').count().get();
      final eventSnapshot = await _firestore.collection('events').count().get();

      // Removed Fetch count for Approved/Ongoing Booking count
      // final approvedOngoingSnapshot = await _firestore.collection('bookings').where('status', whereIn: ['approved', 'ongoing']).count().get();

      // Fetch Pending Bookings (fetch a few, e.g., 3)
      final pendingBookingsSnapshot = await _firestore.collection('bookings').where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).limit(3).get();
      _pendingBookings = pendingBookingsSnapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();

      // Fetch Recent Reviews (fetch a few, e.g., 3)
       final recentReviewsSnapshot = await _firestore.collection('ratings').orderBy('createdAt', descending: true).limit(3).get();
       _recentReviews = recentReviewsSnapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();

      // Fetch Top Booked Class (This requires aggregation, will implement a basic version for now)
      // A more robust solution might involve a backend function or dedicated aggregation query.
      // For simplicity, let's just fetch all bookings and count them by classId.
      final allBookingsSnapshot = await _firestore.collection('bookings').get();
      Map<String, int> bookingCountsByClass = {};
      for (var doc in allBookingsSnapshot.docs) {
        try {
           final booking = BookingModel.fromFirestore(doc);
           // Use roomId (which corresponds to classId in the booking model)
           bookingCountsByClass[booking.roomId] = (bookingCountsByClass[booking.roomId] ?? 0) + 1;
        } catch (e) {
           debugPrint('Error processing booking ${doc.id}: $e');
           // Continue processing other bookings
        }
      }

      if (bookingCountsByClass.isNotEmpty) {
        // Find the classId with the maximum booking count
        final topClassEntry = bookingCountsByClass.entries.reduce((a, b) => a.value > b.value ? a : b);
        final topClassId = topClassEntry.key;
        _topBookedCount = topClassEntry.value;

        // Fetch the ClassModel for the top booked class
        final topClassDoc = await _firestore.collection('classes').doc(topClassId).get();
        if (topClassDoc.exists) {
          _topBookedClass = ClassModel.fromFirestore(topClassDoc);
        } else {
           debugPrint('Top booked class document not found for ID: $topClassId');
           _topBookedClass = null; // Ensure it's null if not found
        }
      } else {
         _topBookedClass = null;
         _topBookedCount = 0;
      }

      setState(() {
        _totalUserCount = userSnapshot.count ?? 0;
        _totalClassCount = classSnapshot.count ?? 0;
        _totalBookingCount = approvedBookingSnapshot.count ?? 0; // Use approved count for Total Bookings
        _totalEventCount = eventSnapshot.count ?? 0;
        // Removed Approved/Ongoing Booking count update
        // _approvedOngoingBookingCount = approvedOngoingSnapshot.count ?? 0;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      setState(() {
        _isLoading = false;
        // Optionally show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: ${e.toString()}')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(                  expandedHeight: 80,                  floating: true,                  pinned: true,                  centerTitle: false,                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,                          children: [
                            Text(
                              'EaseClass',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.notifications_none, color: Colors.white),                      onPressed: () {
                        // TODO: Navigate to Admin Notifications page
                        print('Admin Notification button pressed');
                      },
                    ),
                  ],
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,                      children: [
                        _buildHelloAdmin(),
                        const SizedBox(height: 24.0),
                        _buildOverview(),
                        const SizedBox(height: 24.0),
                        _buildPendingApproval(),
                        const SizedBox(height: 24.0),
                        _buildReviews(),
                        const SizedBox(height: 24.0),
                        _buildTopBookedClass(),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),              ],
            ),    );
  }

  // Widget Builders for each section

  Widget _buildHelloAdmin() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),            child: Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,              children: [
                Text(
                  'Hello, ${_adminUser?.displayName ?? 'Admin'}',                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome to the admin dashboard',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),    );
  }

  Widget _buildOverview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),      child: Padding(
        padding: const EdgeInsets.all(20.0),        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppColors.primary, size: 24),                const SizedBox(width: 12),
                const Text(
                  'Booking Overview',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    Icons.book_outlined,
                    'Total Bookings',
                    _totalBookingCount,
                    Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildOverviewItem(
                    Icons.pending_actions,
                    'Pending Approval',
                    _pendingBookings.length,
                    Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),    );
  }

  Widget _buildOverviewItem(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Container(
           padding: const EdgeInsets.all(12.0), // Padding around icon
           decoration: BoxDecoration(
             color: color.withOpacity(0.1), // Background color based on item
             shape: BoxShape.circle,
           ),
          child: Icon(icon, size: 28.0, color: color), // Icon with specific color
        ),
        const SizedBox(height: 8.0),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApproval() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.orange, size: 24),                const SizedBox(width: 12),
                const Text(
                  'Pending Approval',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),            child: _pendingBookings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, 
                            size: 48, 
                            color: Colors.green.withOpacity(0.5)
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No pending bookings',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pendingBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _pendingBookings[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.orange.withOpacity(0.2)),
                          boxShadow: [
                             BoxShadow(
                               color: Colors.grey.withOpacity(0.05),
                               spreadRadius: 1,
                               blurRadius: 3,
                               offset: const Offset(0, 1),
                             ),
                           ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.pending_actions, 
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,                                      children: [
                                        FutureBuilder<DocumentSnapshot>(
                                          future: _firestore.collection('classes').doc(booking.roomId).get(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData && snapshot.data!.exists) {
                                              final classData = snapshot.data!.data() as Map<String, dynamic>;
                                              return Text(
                                                classData['name'] ?? 'Unknown Class',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              );
                                            }
                                            return const Text(
                                              'Loading...',                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Booking ID: ${booking.id}',                                          style: TextStyle(
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, 
                                              size: 16, 
                                              color: Colors.grey[600]
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              booking.date,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, 
                                              size: 16, 
                                              color: Colors.grey[600]
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              booking.time,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, 
                                              size: 16, 
                                              color: Colors.grey[600]
                                            ),
                                            const SizedBox(width: 8),
                                            FutureBuilder<DocumentSnapshot>(
                                              future: _firestore.collection('users').doc(booking.userId).get(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData && snapshot.data!.exists) {
                                                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                                                  return Text(
                                                    userData['displayName'] ?? 'Unknown User',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 14,
                                                    ),
                                                  );
                                                }
                                                return Text(
                                                  'Loading...',                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 14,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.description_outlined, 
                                              size: 16, 
                                              color: Colors.grey[600]
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                booking.purpose,
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Add See All button
          if (_pendingBookings.length == 3) // Only show if there might be more
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 12.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to Admin All Pending Bookings page
                    print('See All Pending Bookings pressed');
                  },
                  child: const Text('See All'),
                ),
              ),
            ),
        ],
      ),    );
  }

  Widget _buildReviews() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,            blurRadius: 5,
            offset: const Offset(0, 2), // Shadow below
          ),
        ],
      ),      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: AppColors.highlight, size: 24),                const SizedBox(width: 12),
                const Text(
                  'Recent Reviews',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),            child: _recentReviews.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined, 
                            size: 48, 
                            color: Colors.grey.withOpacity(0.5)
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recent reviews',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentReviews.length,
                    itemBuilder: (context, index) {
                      final review = _recentReviews[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppColors.highlight.withOpacity(0.2)),
                          boxShadow: [
                             BoxShadow(
                               color: Colors.grey.withOpacity(0.05),
                               spreadRadius: 1,
                               blurRadius: 3,
                               offset: const Offset(0, 1),
                             ),
                           ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.highlight.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.star, 
                                      color: AppColors.highlight,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,                                    children: [
                                      Text(
                                        'Rating: ${review.rating}',                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12), // Space between rating/icon row and comment
                              Text(
                                review.comment,                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Add See All button
          if (_recentReviews.length == 3) // Only show if there might be more
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 12.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to Admin All Reviews page
                    print('See All Recent Reviews pressed');
                  },
                  child: const Text('See All'),
                ),
              ),
            ),
        ],
      ),    );
  }

  Widget _buildTopBookedClass() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.class_, color: AppColors.primary, size: 24),                const SizedBox(width: 12),
                const Text(
                  'Top Booked Class',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),            child: _topBookedClass == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),                      child: Column(
                        children: [
                          Icon(Icons.class_outlined, 
                            size: 48, 
                            color: Colors.grey.withOpacity(0.5)
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No booking data available yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.class_,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _topBookedClass!.name,
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text(
                            'Booked $_topBookedCount times',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),          ),
        ],
      ),    );
  }
} 