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
import 'admin_bookings_page.dart';
import 'top_booked_classes_page.dart';
import 'booking_management_page.dart';

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
       final recentReviewsSnapshot = await _firestore
           .collection('ratings')
           .orderBy('createdAt', descending: true)
           .limit(5) // Increased limit to show more reviews
           .get();
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EaseClass',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Book with ease',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Welcome Section
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _adminUser?.displayName ?? 'Admin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildStatCard(
                              'Total Users',
                              _totalUserCount.toString(),
                              Icons.people_outline,
                              Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Total Classes',
                              _totalClassCount.toString(),
                              Icons.class_outlined,
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              'Total Bookings',
                              _totalBookingCount.toString(),
                              Icons.book_outlined,
                              AppColors.primary,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Total Events',
                              _totalEventCount.toString(),
                              Icons.event_outlined,
                              Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pending Approvals Section
                        _buildSectionHeader(
                          'Pending Approvals',
                          Icons.pending_actions,
                          AppColors.primary,
                          () {
                            // Navigate to admin bookings page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminBookingsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPendingApprovalsList(),

                        const SizedBox(height: 32),

                        // Recent Reviews Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.highlight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.star,
                                color: AppColors.highlight,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Recent Reviews',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRecentReviewsList(),

                        const SizedBox(height: 32),

                        // Top Booked Class Section
                        _buildSectionHeader(
                          'Top Booked Class',
                          Icons.class_,
                          AppColors.primary,
                          () {
                            // Navigate to top booked classes page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TopBookedClassesPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTopBookedClassCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            'See All',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalsList() {
    if (_pendingBookings.isEmpty) {
      return _buildEmptyState(
        'No pending approvals',
        Icons.check_circle_outline,
        'All bookings have been processed',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingBookings.length,
      itemBuilder: (context, index) {
        final booking = _pendingBookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.pending_actions,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('classes').doc(booking.roomId).get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final classData = snapshot.data!.data() as Map<String, dynamic>;
                                return Text(
                                  classData['name'] ?? 'Unknown Class',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                );
                              }
                              return const Text('Loading...');
                            },
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('users').doc(booking.userId).get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final userData = snapshot.data!.data() as Map<String, dynamic>;
                                return Text(
                                  'Booked by: ${userData['displayName'] ?? 'Unknown User'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                );
                              }
                              return const Text('Loading user info...');
                            },
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
        );
      },
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

  Widget _buildRecentReviewsList() {
    if (_recentReviews.isEmpty) {
      return _buildEmptyState(
        'No reviews',
        Icons.rate_review_outlined,
        'Reviews will appear here',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentReviews.length,
      itemBuilder: (context, index) {
        final review = _recentReviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                        color: AppColors.highlight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.star,
                        color: AppColors.highlight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rating: ${review.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('classes').doc(review.classId).get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final classData = snapshot.data!.data() as Map<String, dynamic>;
                                return Text(
                                  classData['name'] ?? 'Unknown Class',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                );
                              }
                              return const Text('Loading class info...');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  review.comment,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.userName.isEmpty ? 'Anonymous User' : review.userName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildTopBookedClassCard() {
    if (_topBookedClass == null) {
      return _buildEmptyState(
        'No booking data',
        Icons.class_outlined,
        'Class booking data will appear here',
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _topBookedClass!.imageUrl != null && _topBookedClass!.imageUrl!.isNotEmpty
                  ? Image.network(
                      _topBookedClass!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.class_,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.class_,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
            ),
          ),
          // Class Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _topBookedClass!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_topBookedClass!.building} - Floor ${_topBookedClass!.floor}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Booked $_topBookedCount times',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 