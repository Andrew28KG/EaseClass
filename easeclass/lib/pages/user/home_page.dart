import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'dart:async'; // For auto sliding banner
import 'dart:math'; // For min function
import '../../utils/navigation_helper.dart'; // Import navigation helper
import '../../services/firestore_service.dart'; // Import Firestore service
import '../../models/user_model.dart'; // Import User model
import '../../models/room_model.dart'; // Import Room model
import '../../models/booking_model.dart'; // Import Booking model
import '../../models/class_model.dart'; // Import Class model
import '../../models/faq_model.dart'; // Import FAQ model
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import '../../services/auth_service.dart'; // Import Auth Service for admin check
import '../../services/event_service.dart'; // Import Event Service
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for Timestamp if needed, though EventModel handles it
import '../../pages/user/news_page.dart'; // Ensure NewsPage is imported
import '../../models/notification_model.dart';
import 'user_notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _bannerController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  bool _isAdmin = false;
  UserModel? _currentUser;
  List<ClassModel> _availableClasses = [];
  List<ClassModel> _recentClasses = [];
  List<FAQModel> _faqs = [];
  List<BookingModel> _recentBookings = [];
  
  // Use a Stream to get events from Firestore
  final EventService _eventService = EventService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData(); // Initial load of user data
  }

  // Load user data from Firebase (excluding event stream)
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentFirebaseUser = _authService.getCurrentUser();
      if (currentFirebaseUser != null) {
      final currentUser = await _firestoreService.getCurrentUser();
      if (currentUser != null) {
          _isAdmin = await _authService.isCurrentUserAdmin();
        }
      
        // Get all classes and sort them by rating
        final allClasses = await _firestoreService.getClasses();
        allClasses.sort((a, b) => b.rating.compareTo(a.rating));
        
        // Get available classes (isAvailable = true)
        final availableClasses = allClasses.where((classItem) => classItem.isAvailable).toList();
        
        // Get highest rated classes (top 3)
        final highestRatedClasses = allClasses.take(3).toList();
        
        // Get current user's bookings and take only the first 3
        final userBookings = await _firestoreService.getUserBookings(currentFirebaseUser.uid);
        final currentBookings = userBookings
            .where((booking) => booking.status == 'approved' || booking.status == 'pending')
            .take(3) // Limit to a maximum of 3 bookings
            .toList();
        
        // Get FAQs
        final faqs = await _firestoreService.getFAQs();
        
        if (mounted) {
          setState(() {
            _currentUser = currentUser;
            _availableClasses = availableClasses;
            _recentClasses = highestRatedClasses;
            _recentBookings = currentBookings;
            _faqs = faqs;
            _isLoading = false;
          });
        }
      } else {
        NavigationHelper.navigateToLogin(context);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeAnimations() {
    // Animation controller for staggered animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Stream<List<NotificationModel>> _userNotificationsStream() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  Future<void> _markAllNotificationsRead(List<NotificationModel> notifications) async {
    final unread = notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await FirebaseFirestore.instance.collection('notifications').doc(n.id).update({'isRead': true});
    }
  }

  void _showNotificationsDialog(List<NotificationModel> notifications) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: 350,
          child: notifications.isEmpty
              ? const Text('No notifications')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return ListTile(
                      leading: Icon(
                        n.type == 'approved'
                            ? Icons.check_circle
                            : n.type == 'rejected'
                                ? Icons.cancel
                                : Icons.info,
                        color: n.type == 'approved'
                            ? Colors.green
                            : n.type == 'rejected'
                                ? Colors.red
                                : Colors.blue,
                      ),
                      title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(n.body),
                      trailing: n.isRead ? null : const Icon(Icons.fiber_manual_record, color: Colors.blue, size: 12),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    // Mark all as read after dialog is closed
    await _markAllNotificationsRead(notifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          // Custom App Bar with search and notification icons
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: true,
            centerTitle: false,
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
                        'Book rooms with ease',
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
              StreamBuilder<List<NotificationModel>>(
                stream: _userNotificationsStream(),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];
                  final hasUnread = notifications.any((n) => !n.isRead);
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UserNotificationsPage()),
                          );
                        },
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
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
          
          // Page Content
          SliverToBoxAdapter(
        child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [AppColors.subtleShadow],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.secondary.withOpacity(0.1),
                            child: _currentUser?.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.network(
                                      _currentUser!.photoUrl!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 24,
                                    color: AppColors.secondary,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
              Text(
                                  'Welcome, ${_currentUser?.displayName ?? 'User'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                                    Text(
                                  _currentUser?.email ?? '',
                                      style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),

                  // Event Banner Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text(
                            'What\'s New',
                style: TextStyle(
                              fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
                        ),
                        // Use StreamBuilder to listen to events from Firestore
                        StreamBuilder<List<EventModel>>(
                          stream: _eventService.getEventsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error loading events: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text('No events available yet.', style: TextStyle(color: Colors.grey[600])),
                                ),
                              );
                            }

                            final List<EventModel> events = snapshot.data!;

                            // Pass events to the new slider widget
                            return _EventSliderWidget(
                              events: events,
                              bannerController: _bannerController,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

              // Current Bookings Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Bookings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Use navigateToTab to switch to the bookings tab (index 2 for user)
                                NavigationHelper.navigateToTab(context, 2);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'See All',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.secondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _recentBookings.isEmpty 
                          ? const Center(
                                child: Text(
                                'No current bookings.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentBookings.length,
                              itemBuilder: (context, index) {
                                final booking = _recentBookings[index];
                                
                                // Determine status color and icon
                                Color statusColor;
                                IconData statusIcon;
                                
                                if (booking.status == 'pending') {
                                  statusColor = Colors.orange;
                                  statusIcon = Icons.pending_actions;
                                } else if (booking.status == 'approved') {
                                  statusColor = Colors.blue;
                                  statusIcon = Icons.event_available;
                                } else {
                                  statusColor = Colors.green;
                                  statusIcon = Icons.check_circle;
                                }
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      // Navigate to booking detail page
                                      NavigationHelper.navigateToUserBookingDetails(context, booking);
                                    },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            statusIcon,
                                            color: statusColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  booking.roomDetails != null 
                                                      ? (booking.roomDetails!['name'] as String? ?? 'Room ${booking.roomId.substring(0, min(6, booking.roomId.length))}')
                                                      : 'Room ${booking.roomId.substring(0, min(6, booking.roomId.length))}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                'Date: ${booking.date}',
                                                style: TextStyle(color: AppColors.black.withOpacity(0.6), fontSize: 14),
                                              ),
                                              Text(
                                                'Time: ${booking.time}',
                                                style: TextStyle(color: AppColors.black.withOpacity(0.6), fontSize: 14),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: statusColor),
                                                  ),
                                                  child: Text(
                                                    booking.status.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: statusColor,
                                                    ),
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
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Available Classes Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
              Text(
                'Available Classrooms',
                style: TextStyle(
                                fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                            ),
                            GestureDetector(
                              onTap: () {
                                NavigationHelper.navigateToAvailableClasses(context);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'See All',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.secondary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
              ),
              const SizedBox(height: 10),
                        _buildAvailableClassesSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Highest Rated Classes Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Highest Rated Classrooms',
                              style: TextStyle(
                                fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Use navigateToTab to switch to the available classes tab (index 1)
                                NavigationHelper.navigateToAvailableClasses(
                                  context,
                                  applyFilter: {'ratingSort': 'Highest to Lowest'},
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'See All',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.secondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
              ),
              const SizedBox(height: 10),
              _recentClasses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No rated classrooms available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: min(3, _recentClasses.length),
                    itemBuilder: (context, index) {
                      final room = _recentClasses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                      onTap: () {
                                  // Navigate to class detail page instead of room detail
                                  NavigationHelper.navigateToClassDetails(context, room);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                            child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Room image placeholder
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                  child: room.imageUrl != null && room.imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            room.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.meeting_room,
                                              size: 36,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                              Icons.meeting_room,
                                              size: 36,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                      Text(
                                        room.name,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                                Text(
                                        'Building ${room.building} - Floor ${room.floor}',
                                        style: const TextStyle(
                                                    fontSize: 14,
                                          color: Colors.grey,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: AppColors.highlight,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                                Text(
                                            '${room.rating.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.highlight,
                                                  ),
                                                ),
                                              ],
                                      ),
                                    ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                  size: 16,
                                            color: AppColors.secondary,
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  );
                },
              ),
                      ],
                    ),
                  ),

              // FAQ Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40), // Increased space from navbar
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                            fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
                        StreamBuilder<List<FAQModel>>(
                          stream: _firestoreService.getFAQsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error loading FAQs: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                    'No FAQs available yet.',
                                    style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              );
                            }

                            final List<FAQModel> faqs = snapshot.data!.take(5).toList(); // Limit to 5 FAQs
                            return Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: faqs.length,
                                  itemBuilder: (context, index) {
                                    final faq = faqs[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ExpansionTile(
                                    title: Text(
                                      faq.question,
                                      style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                      ),
                                    ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                                          faq.answer,
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontSize: 14,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                          },
                            ),
                                const SizedBox(height: 16),
                                TextButton(
                                onPressed: () {
                                    // Use navigateToTab to switch to the profile tab (index 3 for user)
                                    NavigationHelper.navigateToTab(context, 3);
                                },
                                  child: const Text('View more FAQs in Profile'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                              ),
                            ),
                              ],
                            );
                          },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableClassesSection() {
    return Container(
      height: 200, // Adjusted height
      child: _availableClasses.isEmpty
          ? Center(child: Text('No available classes found'))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: min(5, _availableClasses.length),
              itemBuilder: (context, index) {
                final classItem = _availableClasses[index];
                return InkWell(
                  onTap: () {
                    // Navigate to class details page
                    _navigateToClassDetails(context, classItem);
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [AppColors.subtleShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.class_,
                              size: 40,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Consistent vertical padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      classItem.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${classItem.building} - Floor ${classItem.floor}',
                                      style: TextStyle(
                                        color: AppColors.darkGrey,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8), // Added fixed space
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      classItem.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: AppColors.darkGrey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                  ),
                ],
              ),
            ),
          ),
        ],
                    ),
                  ),
                );
              },
      ),
    );
  }

  // Update the navigation method in the "See All" button
  void _navigateToAvailableClasses(BuildContext context) {
    NavigationHelper.navigateToAvailableClasses(context);
  }

  // Update the navigation method in the "See All" button for highest rated classes
  void _navigateToHighestRatedClasses(BuildContext context) {
    NavigationHelper.navigateToAvailableClasses(
      context,
      applyFilter: {'ratingSort': 'Highest to Lowest'},
    );
  }

  // Update the navigation method for class details
  void _navigateToClassDetails(BuildContext context, ClassModel classModel) {
    NavigationHelper.navigateToClassDetails(context, classModel);
  }
}

// New StatefulWidget to manage the event slider and its index state
class _EventSliderWidget extends StatefulWidget {
  final List<EventModel> events;
  final PageController bannerController;

  const _EventSliderWidget({
    Key? key,
    required this.events,
    required this.bannerController,
  }) : super(key: key);

  @override
  __EventSliderWidgetState createState() => __EventSliderWidgetState();
}

class __EventSliderWidgetState extends State<_EventSliderWidget> {
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  @override
  void didUpdateWidget(covariant _EventSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart timer if the list of events changes
    if (widget.events.length != oldWidget.events.length) {
      _startBannerTimer();
    } else if (widget.events.isNotEmpty && oldWidget.events.isNotEmpty) {
       // Check if content of events changed (simple check)
       bool contentChanged = false;
       for(int i = 0; i < widget.events.length; i++){
         if(widget.events[i].id != oldWidget.events[i].id || 
            widget.events[i].title != oldWidget.events[i].title || 
            widget.events[i].description != oldWidget.events[i].description || 
            widget.events[i].imageUrl != oldWidget.events[i].imageUrl){
           contentChanged = true;
           break;
         }
       }
       if(contentChanged) {
         _startBannerTimer();
       }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel(); // Cancel any existing timer
    if (widget.events.isNotEmpty) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        int nextIndex = _currentBannerIndex + 1;
        if (nextIndex >= widget.events.length) {
          nextIndex = 0;
        }
        if (widget.bannerController.hasClients) {
           widget.bannerController.animateToPage(
             nextIndex,
             duration: const Duration(milliseconds: 500),
             curve: Curves.easeInOut,
           );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;

    return Column(
      children: [
        SizedBox(
          height: 200, // Increased height to allow more space for description
          child: PageView.builder(
            controller: widget.bannerController,
            itemCount: events.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(context, event); // Use the helper
            },
          ),
        ),
        const SizedBox(height: 8),
        // Banner Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            events.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: index == _currentBannerIndex ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: index == _currentBannerIndex
                    ? AppColors.primary
                    : AppColors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build an event card for the banner
  Widget _buildEventCard(BuildContext context, EventModel event) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => NewsPage()));
      },
              child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
                        ),
                      ],
        ),
        child: Stack(
          children: [
            // Background image
            if (event.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  event.imageUrl,
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600])),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),

            // Gradient Overlay for text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Content (Title and Description)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(), // This will push the content to the bottom
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                    ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}