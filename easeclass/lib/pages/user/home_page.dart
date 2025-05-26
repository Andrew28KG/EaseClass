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
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  List<RoomModel> _availableRooms = [];
  List<ClassModel> _recentClasses = []; // Renamed from _availableClasses to use it for Recent Classes
  List<BookingModel> _recentBookings = [];
  List<FAQModel> _faqs = [];
  bool _isLoading = true;
  bool _isAdmin = false; // Admin flag for conditional rendering
  
  // Banner events will be based on available classes
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Start auto-sliding banner
    _startBannerTimer();
    // Load user data from Firebase
    _loadUserData();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user
      final currentUser = await _firestoreService.getCurrentUser();
      
      // Check if user is admin
      if (currentUser != null) {
        final currentFirebaseUser = FirebaseAuth.instance.currentUser;
        if (currentFirebaseUser != null) {
          // Check admin status using the authService
          _isAdmin = await _authService.isCurrentUserAdmin();
        }
      }
      
      if (currentUser != null) {
        // Get available rooms
        final availableRooms = await _firestoreService.getAvailableRooms();
        
        // Get available classes
        final availableClasses = await _firestoreService.getAvailableClasses();
        
        // Get user bookings - upcoming and pending ones for current bookings
        final currentBookings = await _firestoreService.getOngoingBookings();
        
        // Get FAQs
        final faqs = await _firestoreService.getFAQs();
        
        // Sort available rooms by rating
        availableRooms.sort((a, b) => b.rating.compareTo(a.rating));
        
        // Create events from classes
        final List<Map<String, dynamic>> events = [];
        
        // Use the first 3 classes for events
        for (int i = 0; i < min(3, availableClasses.length); i++) {
          final classItem = availableClasses[i];
          events.add({
            'title': classItem.name,
            'description': 'Building ${classItem.building}, Floor ${classItem.floor}',
            'color': [
              i == 0 ? AppColors.primary : (i == 1 ? AppColors.secondary : AppColors.accent),
              i == 0 ? AppColors.primaryLight : (i == 1 ? AppColors.secondaryLight : AppColors.accentLight),
            ],
            'icon': _getIconForClass(classItem),
          });
        }
        
        if (mounted) {
          setState(() {
            _currentUser = currentUser;
            _availableRooms = availableRooms;
            _recentClasses = availableClasses;
            _recentBookings = currentBookings.take(3).toList();
            _faqs = faqs;
            _events = events;
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
  
  // Helper method to get icon for a class based on its features or metadata
  IconData _getIconForClass(ClassModel classItem) {
    final metadata = classItem.metadata;
    final courseCode = metadata?['courseCode'] as String? ?? '';
    
    if (courseCode.startsWith('CS')) {
      return Icons.computer_rounded;
    } else if (courseCode.startsWith('MATH')) {
      return Icons.calculate_rounded;
    } else if (courseCode.startsWith('CHEM')) {
      return Icons.science_rounded;
    } else if (courseCode.startsWith('PSYC')) {
      return Icons.psychology_rounded;
    } else if (courseCode.startsWith('MKT')) {
      return Icons.trending_up_rounded;
    } else {
      return Icons.school_rounded;
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
                                                    backgroundColor: _events[index]['color'][0],
                                                    child: Icon(
                                                      _events[index]['icon'],
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      _events[index]['title'],
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
                                                _events[index]['description'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Location',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Building ${_events[index]['description'].toString().split(', ')[0].replaceAll('Building ', '')}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
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
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      // Additional action if needed
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _events[index]['color'][0],
                                                      foregroundColor: Colors.white,
                                                    ),
                                                    child: const Text('Learn More'),
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
                child: _availableRooms.isEmpty
                    ? Center(child: Text('No available rooms found'))
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
                                                'Room ${room.id.substring(0, min(6, room.id.length))}', // Truncate ID for display
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
                                        const SizedBox(height: 4),
                                        Text(
                                          'Building ${room.building}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Floor ${room.floor}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
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
                                                fontSize: 11,
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
                      final classItem = _recentClasses[index];
                      final roomFeatures = [
                        ['Smart Projector', 'Air Conditioning', 'Adjustable Lighting'],
                        ['Surround Sound', 'Smart Boards', 'Ergonomic Furniture'],
                        ['Video Conferencing', 'Recording Equipment', 'High-speed Internet']
                      ][index % 3]; // Use modulo to handle any number of classes
                      
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
                                  NavigationHelper.navigateToRoomDetail(
                                    context,
                                    {
                                      'roomId': classItem.id,
                                      'building': classItem.building,
                                      'floor': classItem.floor,
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
                                                        'Premium Room ${classItem.id.substring(0, min(6, classItem.id.length))}',
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
                                                              classItem.rating.toStringAsFixed(1),
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
                                                  'Building ${classItem.building}, Floor ${classItem.floor}',
                                                  style: TextStyle(
                                                    color: AppColors.black.withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Capacity: ${classItem.capacity} students',
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
                        _faqs.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'FAQs are not available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : Column(
                              children: _faqs.take(5).map((faq) { // Show first 5 FAQs
                                return Card(
                                  child: ExpansionTile(
                                    title: Text(faq.question),
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
                            ),
                        if (_faqs.length > 5)
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