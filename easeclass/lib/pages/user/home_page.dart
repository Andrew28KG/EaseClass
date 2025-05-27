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

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final PageController _bannerController = PageController();
  late AnimationController _animationController;
  Animation<double> _fadeAnimation = AlwaysStoppedAnimation(1.0);
  
  // Firebase services
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  List<RoomModel> _availableRooms = [];
  List<RoomModel> _recentClasses = []; // Renamed from _availableClasses to use it for Recent Classes
  List<BookingModel> _recentBookings = [];
  List<FAQModel> _faqs = [];
  bool _isLoading = true;
  bool _isAdmin = false; // Admin flag for conditional rendering
  
  // Use a Stream to get events from Firestore
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData(); // Initial load of user data
  }

  // Load user data from Firebase (excluding event stream)
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = await _firestoreService.getCurrentUser();
      if (currentUser != null) {
        final currentFirebaseUser = FirebaseAuth.instance.currentUser;
        if (currentFirebaseUser != null) {
          _isAdmin = await _authService.isCurrentUserAdmin();
        }
      
        // Get all rooms and sort them by rating
        final allRooms = await _firestoreService.getRooms();
        allRooms.sort((a, b) => b.rating.compareTo(a.rating));
        
        // Get available rooms (isAvailable = true)
        final availableRooms = allRooms.where((room) => room.isAvailable).toList();
        
        // Get highest rated rooms (top 3)
        final highestRatedRooms = allRooms.take(3).toList();
        
        // Get FAQs
        final faqs = await _firestoreService.getFAQs();
        debugPrint('Fetched ${faqs.length} FAQs.');
        
        if (mounted) {
          setState(() {
            _currentUser = currentUser;
            _availableRooms = availableRooms;
            _recentClasses = highestRatedRooms; // Use highest rated rooms instead of classes
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
            // Notification icon removed as requested
            actions: [],
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
                            radius: 22, // Smaller avatar
                            backgroundColor: AppColors.secondary.withOpacity(0.1),
                            child: _currentUser?.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.network(
                                      _currentUser!.photoUrl!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(
                                            Icons.person_rounded,
                                            color: AppColors.secondary,
                                            size: 22,
                                          ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    color: AppColors.secondary,
                                    size: 22, // Smaller icon
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
              const Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 12, // Smaller text
                                  color: AppColors.darkGrey,
                                ),
                              ),
              Text(
                                _currentUser?.displayName ?? _currentUser?.email ?? 'User',
                                style: TextStyle(
                                  fontSize: 16, // Smaller text
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          // Add admin panel button if user is admin
                          if (_isAdmin)
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to admin dashboard
                                  NavigationHelper.navigateToAdminDashboard(context);
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings,
                                      color: AppColors.secondary,
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Admin',
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Notification icon removed as requested
                        ],
                      ),
                    ),
                  ),

                  // Auto-sliding Top Event Banner
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
                              // Stop the timer if there are no events
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text('No events available yet.', style: TextStyle(color: Colors.grey[600])), // Added subtle styling
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
                                NavigationHelper.navigateToProgress(context);
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
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No upcoming bookings',
                                  style: TextStyle(color: Colors.grey),
                                ),
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
                                } else if (booking.status == 'upcoming') {
                                  statusColor = Colors.blue;
                                  statusIcon = Icons.event_available;
                                } else {
                                  statusColor = Colors.green;
                                  statusIcon = Icons.check_circle;
                                }
                                
                                return Card(
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
                                                'Room ${booking.roomId.substring(0, min(6, booking.roomId.length))}',
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
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

              // Available Rooms Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header with see all link
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
                            // See All button
                            GestureDetector(
                              onTap: () {
                                NavigationHelper.navigateToAvailableRooms(context);
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
              Container(
                height: 180,
                child: _availableRooms.isEmpty
                    ? Center(child: Text('No available classrooms found'))
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                        itemCount: min(5, _availableRooms.length),
                  itemBuilder: (context, index) {
                          final room = _availableRooms[index];
                          return InkWell(
                            onTap: () {
                              NavigationHelper.navigateToRoomDetail(
                                context,
                                {
                                  'roomId': room.id,
                                  'building': room.building,
                                  'floor': room.floor,
                                },
                              );
                            },
                            child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: index % 2 == 0 ? AppColors.primary.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1),
                        border: Border.all(
                          color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                          width: 1,
                        ),
                      ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Room image section
                                  ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(11),
                                      topRight: Radius.circular(11),
                                    ),
                                    child: Container(
                                      height: 80,
                                      width: double.infinity,
                                      child: room.imageUrl != null && room.imageUrl!.isNotEmpty
                                          ? Image.network(
                                              room.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: index % 2 == 0 ? AppColors.primary.withOpacity(0.2) : AppColors.secondary.withOpacity(0.2),
                                                child: Icon(
                                                  Icons.meeting_room,
                                                  size: 40,
                                                  color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: index % 2 == 0 ? AppColors.primary.withOpacity(0.2) : AppColors.secondary.withOpacity(0.2),
                                              child: Icon(
                                                Icons.meeting_room,
                                                size: 40,
                                                color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Room details section
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                                ),
                                              ),
                                            child: Text(
                                                room.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.star,
                                              color: AppColors.highlight,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Building ${room.building}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Floor ${room.floor}',
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        // Rating row
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Rating: ',
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                            ...List.generate(
                                              5,
                                              (starIndex) => Icon(
                                                starIndex < room.rating.floor() 
                                                    ? Icons.star 
                                                    : (starIndex < room.rating ? Icons.star_half : Icons.star_border),
                                                color: AppColors.highlight,
                                                size: 12,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              '${room.rating.toStringAsFixed(1)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 10,
                                              color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
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
                                NavigationHelper.navigateToAvailableRooms(
                                  context,
                                  applyFilter: {'ratingSort': 'Highest to Lowest'}
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
                                  NavigationHelper.navigateToRoomDetail(
                                    context,
                                    {
                                'roomId': room.id,
                                'building': room.building,
                                'floor': room.floor,
                                    },
                                  );
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
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                            fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
                        // Use StreamBuilder to listen for real-time FAQ updates
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
                                  'FAQs are not available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              );
                            }

                            final faqs = snapshot.data!;

                            return Column(
                              children: faqs.take(5).map((faq) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ExpansionTile(
                                    title: Text(
                                      faq.question,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                textColor: AppColors.secondary,
                iconColor: AppColors.accent,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                                          faq.answer,
                      style: TextStyle(color: AppColors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                            ),
                        if (_faqs.length > 5) // This check still uses the old _faqs list, should be updated if needed
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextButton.icon(
                                onPressed: () {
                                  // Navigate to full FAQ page
                                  NavigationHelper.navigateToSettings(context);
                                },
                                icon: Icon(Icons.help_outline),
                                label: Text('See More FAQs'),
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
        ],
      ),
    );
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
    return GestureDetector(
      onTap: () {
        // Show popup dialog with event details
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.event,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    if (event.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          event.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: TextStyle(color: AppColors.secondary),
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
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppColors.cardShadow],
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
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),

            // Content (Title and Description)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 3, // Increase max lines to show more description on the card
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