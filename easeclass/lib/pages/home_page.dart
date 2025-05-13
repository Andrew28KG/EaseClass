import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dart:async'; // For auto sliding banner
import '../utils/navigation_helper.dart'; // Import navigation helper
import '../services/firestore_service.dart'; // Import Firestore service
import '../models/user_model.dart'; // Import User model
import '../models/room_model.dart'; // Import Room model
import '../models/booking_model.dart'; // Import Booking model
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  late AnimationController _animationController;
  Animation<double> _fadeAnimation = AlwaysStoppedAnimation(1.0);
  
  // Firebase services
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentUser;
  List<RoomModel> _availableRooms = [];
  List<BookingModel> _recentBookings = [];
  bool _isLoading = true;
  
  // Sample events data for the banner
  final List<Map<String, dynamic>> _events = [
    {
      'title': 'New Computer Lab Opening',
      'description': 'Building A, 3rd Floor',
      'color': [AppColors.primary, AppColors.primaryLight],
      'icon': Icons.computer_rounded,
    },
    {
      'title': 'Extended Hours Weekend',
      'description': 'Reserve rooms until 10PM',
      'color': [AppColors.secondary, AppColors.secondaryLight],
      'icon': Icons.access_time_rounded,
    },
    {
      'title': 'Maintenance Notice',
      'description': 'Building B closed on Saturday',
      'color': [AppColors.accent, AppColors.accentLight],
      'icon': Icons.build_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Start auto-sliding banner
    _startBannerTimer();
    // Load user data from Firebase
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user
      final currentUser = await _firestoreService.getCurrentUser();
      
      if (currentUser != null) {
        // Get available rooms
        final availableRooms = await _firestoreService.getAvailableRooms();
        
        // Get user bookings
        final userBookings = await _firestoreService.getUserBookings();
        
        // Sort available rooms by rating
        availableRooms.sort((a, b) => b.rating.compareTo(a.rating));
        
        // Filter recent completed bookings
        final recentBookings = userBookings
            .where((booking) => booking.isCompleted)
            .take(3)
            .toList();
        
        if (mounted) {
          setState(() {
            _currentUser = currentUser;
            _availableRooms = availableRooms;
            _recentBookings = recentBookings;
            _isLoading = false;
          });
        }
      } else {
        // If no user is logged in, navigate to login page
        NavigationHelper.navigateToLogin(context);
      }
    } catch (e) {
      print('Error loading data: $e');
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
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentBannerIndex < _events.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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
              IconButton(
                icon: const Icon(Icons.notifications_rounded, size: 22),
                onPressed: () {
                  // Show notifications
                },
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(width: 8),
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
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          )
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
                        SizedBox(
                          height: 160, // Reduced height
                          child: PageView.builder(
                            controller: _bannerController,
                            itemCount: _events.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _events[index]['color'][0],
                                      _events[index]['color'][1],
                                    ],
                                  ),
                                  boxShadow: [AppColors.cardShadow],
                                ),
                                child: Stack(
                                  children: [
                                    // Background decoration
                                    Positioned(
                                      right: -40,
                                      top: -40,
                                      child: CircleAvatar(
                                        radius: 80,
                                        backgroundColor: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    // Content
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Event icon
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Colors.white.withOpacity(0.2),
                                            child: Icon(
                                              _events[index]['icon'],
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Event details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _events[index]['title'],
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _events[index]['description'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                // Learn more button
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Text(
                                                    'Learn more',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
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
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Banner Indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _events.length,
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
                              'Available Rooms',
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
                          height: 160, // Reduced from 180
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/room-detail',
                                    arguments: {
                                      'roomId': index + 101,
                                      'building': String.fromCharCode(65 + (index % 3)),
                                      'floor': (index % 3) + 1,
                                    },
                                  );
                                },
                                child: Container(
                                  width: 200, // Slightly reduced
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: index % 2 == 0 ? AppColors.primary.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1),
                                    border: Border.all(
                                      color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                                ),
                                              ),
                                              child: Text(
                                                'Room ${index + 101}',
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
                                        const SizedBox(height: 8),
                                        Text(
                                          'Building ${String.fromCharCode(65 + (index % 3))}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Floor ${(index % 3) + 1}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Capacity: ${20 + (index * 5)} students',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const Spacer(),
                                        // Rating row
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Rating: ',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            ...List.generate(
                                              5,
                                              (starIndex) => Icon(
                                                starIndex < (4.0 + (index % 2) * 0.5).floor()
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: AppColors.highlight,
                                                size: 10,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              '${4.0 + (index % 2) * 0.5}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
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
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recently Booked Classes
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recently Booked Classes',
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            // Only showing completed bookings
                            final daysAgo = index + 2; // At least 2 days ago to ensure they're completed
                            return Card(
                              child: InkWell(
                                onTap: () {
                                  // Navigate to booking detail
                                  NavigationHelper.navigateToProgressDetail(
                                    context,
                                    {
                                      'bookingId': index + 1,
                                      'roomId': 101 + index,
                                      'date': DateTime.now().subtract(Duration(days: daysAgo)).toString().split(' ')[0],
                                      'time': '${9 + index}:00 - ${10 + index}:00',
                                      'status': 'Completed',
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Room ${101 + index}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Date: ${DateTime.now().subtract(Duration(days: daysAgo)).toString().split(' ')[0]}',
                                              style: TextStyle(color: AppColors.black.withOpacity(0.6), fontSize: 14),
                                            ),
                                            Text(
                                              'Time: ${9 + index}:00 - ${10 + index}:00',
                                              style: TextStyle(color: AppColors.black.withOpacity(0.6), fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppColors.primary,
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            final rating = 4.7 + (index * 0.1);
                            final roomFeatures = [
                              ['Smart Projector', 'Air Conditioning', 'Adjustable Lighting'],
                              ['Surround Sound', 'Smart Boards', 'Ergonomic Furniture'],
                              ['Video Conferencing', 'Recording Equipment', 'High-speed Internet']
                            ][index];
                            
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Navigate to room detail
                                  Navigator.pushNamed(
                                    context,
                                    '/room-detail',
                                    arguments: {
                                      'roomId': 201 + index,
                                      'building': String.fromCharCode(65 + (index % 3)),
                                      'floor': (index % 3) + 1,
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
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
                                            child: Icon(
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
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Premium Room ${201 + index}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.highlight.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.star, color: AppColors.highlight, size: 16),
                                                          SizedBox(width: 2),
                                                          Text(
                                                            rating.toStringAsFixed(1),
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: AppColors.highlight,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  'Building ${String.fromCharCode(65 + (index % 3))}, Floor ${(index % 3) + 1}',
                                                  style: TextStyle(
                                                    color: AppColors.black.withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Capacity: ${30 + (index * 10)} students',
                                                  style: TextStyle(
                                                    color: AppColors.black.withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Divider(),
                                      SizedBox(height: 6),
                                      Text(
                                        'Room Features:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: roomFeatures.map((feature) => Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.primary.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            feature,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'View Details',
                                            style: TextStyle(
                                              color: AppColors.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: AppColors.secondary,
                                          ),
                                        ],
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
                        Card(
                          child: ExpansionTile(
                            title: const Text('How do I book a class?'),
                            textColor: AppColors.secondary,
                            iconColor: AppColors.accent,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'You can book a class by browsing available rooms, selecting a room, choosing your preferred date and time slot, and confirming the booking. The system will then reserve the room for you.',
                                  style: TextStyle(color: AppColors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          child: ExpansionTile(
                            title: const Text('Can I cancel my booking?'),
                            textColor: AppColors.secondary,
                            iconColor: AppColors.accent,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Yes, you can cancel your booking up to 24 hours before the scheduled time without any penalty. Go to My Bookings, select the booking you want to cancel, and tap the Cancel Booking button.',
                                  style: TextStyle(color: AppColors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          child: ExpansionTile(
                            title: const Text('What equipment is available in rooms?'),
                            textColor: AppColors.secondary,
                            iconColor: AppColors.accent,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Most rooms are equipped with projectors, whiteboards, and air conditioning. Specialized rooms may have additional equipment like computers, lab equipment, or audio-visual systems. Check the room details page for specific information.',
                                  style: TextStyle(color: AppColors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          child: ExpansionTile(
                            title: const Text('How early can I book a room?'),
                            textColor: AppColors.secondary,
                            iconColor: AppColors.accent,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'You can book rooms up to 30 days in advance. For special events or recurring bookings, please contact the administration office.',
                                  style: TextStyle(color: AppColors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          child: ExpansionTile(
                            title: const Text('Can I extend my booking time?'),
                            textColor: AppColors.secondary,
                            iconColor: AppColors.accent,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'If the room is available after your booked time slot, you may extend your booking through the app. Go to your current booking and select "Extend Booking" option. Note that extension is subject to availability.',
                                  style: TextStyle(color: AppColors.black),
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
        ],
      ),
    );
  }
} 