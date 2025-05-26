import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';
import 'pages/user/home_page.dart';
import 'pages/user/available_rooms_page.dart';
import 'pages/user/room_detail_page.dart';
import 'pages/user/user_bookings_page.dart'; // User's BookingsPage for user navigation
import 'pages/user/progress_detail_page.dart';
import 'pages/user/settings_page.dart';
import 'pages/user/booking_confirmation_page.dart';
import 'pages/user/rating_page.dart';
import 'pages/auth_page.dart'; // Unified login page
import 'pages/admin/admin_main_page.dart';
import 'pages/admin/manage_page.dart';
import 'services/database_initializer.dart';
import 'services/auth_service.dart';

Future<void> initializeFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      // Firebase is already initialized
      return;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  
  // Initialize database with sample data
  final dbInitializer = DatabaseInitializer();
  await dbInitializer.initializeDatabase();
    // Create an instance of AuthService
  final authService = AuthService();
  runApp(
    MultiProvider(
      providers: [
        StreamProvider<User?>(
          create: (_) => authService.authStateChanges,
          initialData: null,
        ),
        Provider<AuthService>(
          create: (_) => authService,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EaseClass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          primaryContainer: AppColors.primaryLight,
          onPrimary: AppColors.white,
          secondary: AppColors.secondary,
          secondaryContainer: AppColors.secondaryLight,
          onSecondary: AppColors.white,
          tertiary: AppColors.highlight,
          tertiaryContainer: AppColors.highlightLight,
          onTertiary: AppColors.white,
          error: AppColors.error,
          errorContainer: AppColors.accentLight,
          onError: AppColors.white,
          background: AppColors.background,
          surface: AppColors.white,
          surfaceVariant: AppColors.lightGrey,
        ),
        scaffoldBackgroundColor: AppColors.background,
        
        textTheme: const TextTheme(
          displayLarge: AppTypography.headline1,
          displayMedium: AppTypography.headline2,
          displaySmall: AppTypography.headline3,
          headlineMedium: AppTypography.subtitle1,
          bodyLarge: AppTypography.body1,
          bodyMedium: AppTypography.body2,
          labelLarge: AppTypography.button,
          bodySmall: AppTypography.caption,
        ),
        
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),        ),        
        cardTheme: const CardThemeData(
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppStyles.primaryButtonStyle,
        ),
        textButtonTheme: TextButtonThemeData(
          style: AppStyles.textButtonStyle,
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightGrey,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
        ),
        
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.darkGrey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
        ),
        
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.primary,
          contentTextStyle: const TextStyle(color: AppColors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),      // Authentication Routing Logic
      home: Provider.of<User?>(context) == null 
          ? const AuthPage() 
          : FutureBuilder<bool>(
              future: Provider.of<AuthService>(context, listen: false).isCurrentUserAdmin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final isAdmin = snapshot.data ?? false;
                return isAdmin ? const AdminMainPage() : const MainPage();
              },
            ),        routes: {
        '/login': (context) => const AuthPage(),
        '/home': (context) => FutureBuilder<bool>(
          future: Provider.of<AuthService>(context, listen: false).isCurrentUserAdmin(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            final isAdmin = snapshot.data ?? false;
            return isAdmin ? const AdminMainPage() : const MainPage();
          },
        ),        '/room-detail': (context) => const RoomDetailPage(),
        '/booking-confirmation': (context) => const BookingConfirmationPage(),
        '/progress-detail': (context) => const ProgressDetailPage(),
        '/rating': (context) => const RatingPage(),
        '/admin-dashboard': (context) => const AdminMainPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Dashboard
    GlobalKey<NavigatorState>(), // Available Rooms
    GlobalKey<NavigatorState>(), // Management (admin) or Bookings (user)
    GlobalKey<NavigatorState>(), // Bookings (admin) or Profile (user)
    GlobalKey<NavigatorState>(), // Profile (admin)
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for arguments when dependencies change (including first build)
    _checkForTabArguments();
  }

  void _checkForTabArguments() {
    final Object? args = ModalRoute
        .of(context)
        ?.settings
        .arguments;
    // Only handle numerical tab indices, nothing else
    if (args != null && args is int && args >= 0 &&
        args < _navigatorKeys.length) {
      // Only update if it's different to avoid unnecessary rebuilds
      if (_selectedIndex != args) {
        // Use a post-frame callback to avoid potential build issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedIndex = args;
          });
        });
      }
    }
  }

  // Update the routing logic in MainPage class

  // Inside _MainPageState class, update the _onItemTapped method
  void _onItemTapped(int index) {
    // Ensure we don't exceed the available navigator keys
    if (index < _navigatorKeys.length) {
      if (_selectedIndex == index) {
        // If user taps on the active tab, try to pop to root
        _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _selectedIndex = index;
        });
      }
    }
  }

  // Update the build method to handle admin vs user navigation properly
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Try to pop the current navigator first
        final NavigatorState currentNavigator = _navigatorKeys[_selectedIndex]
            .currentState!;
        if (currentNavigator.canPop()) {
          currentNavigator.pop();
          return false;
        }

        // If we're not on the home tab, go there instead of exiting
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }

        // If we're already on the home tab, implement double-back-to-exit
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: FutureBuilder<bool>(
          future: Provider.of<AuthService>(context, listen: false)
              .isCurrentUserAdmin(),
          builder: (context, snapshot) {
            final isAdmin = snapshot.data ?? false;

            return Stack(
              children: [
                _buildPageNavigator(0),
                _buildPageNavigator(1),
                _buildPageNavigator(2),
                _buildPageNavigator(3),
                isAdmin ? _buildPageNavigator(4) : const SizedBox.shrink(),
              ],
            );
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: FutureBuilder<bool>(
              future: Provider.of<AuthService>(context, listen: false)
                  .isCurrentUserAdmin(),
              builder: (context, snapshot) {
                final isAdmin = snapshot.data ?? false;

                // Determine the actual index to highlight in the bottom navigation bar
                return BottomNavigationBar(
                  items: <BottomNavigationBarItem>[
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      activeIcon: Icon(Icons.dashboard_rounded),
                      label: 'Dashboard',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.meeting_room_outlined),
                      activeIcon: Icon(Icons.meeting_room_rounded),
                      label: 'Available Rooms',
                    ),
                    if (isAdmin)
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.admin_panel_settings_outlined),
                        activeIcon: Icon(Icons.admin_panel_settings),
                        label: 'Management',
                      ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.history_outlined),
                      activeIcon: Icon(Icons.history_rounded),
                      label: 'Bookings',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Build the navigation for a specific tab
  Widget _buildPageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) {
          // Check if this is a route that needs to be handled by a specific tab
          if (settings.name == '/room-detail' ||
              settings.name == '/booking-confirmation' ||
              settings.name == '/progress-detail' ||
              settings.name == '/rating') {
            return MaterialPageRoute(
              builder: (context) {
                // Route to the correct page based on the route name
                switch (settings.name) {
                  case '/room-detail':
                    return const RoomDetailPage();
                  case '/booking-confirmation':
                    return const BookingConfirmationPage();
                  case '/progress-detail':
                    return const ProgressDetailPage();
                  case '/rating':
                    return const RatingPage();
                  default:
                  // This shouldn't happen, but just in case
                    return const HomePage();
                }
              },
              settings: settings,
            );
          } // Default page for each tab
          return MaterialPageRoute(
            builder: (context) {
              // Check if the user is admin to determine the correct tab index mapping
              return FutureBuilder<bool>(
                future: Provider.of<AuthService>(context, listen: false)
                    .isCurrentUserAdmin(),
                builder: (context, snapshot) {
                  final bool isAdminUser = snapshot.connectionState ==
                      ConnectionState.done ? (snapshot.data ?? false) : false;

                  if (isAdminUser) {
                    // Admin navigation
                    switch (index) {
                      case 0:
                        return const HomePage();
                      case 1:
                        return const AvailableRoomsPage();
                      case 2:
                      // For admins, tab 2 is Management
                        final manageTabIndex = settings.arguments is int
                            ? settings.arguments as int
                            : null;
                        return ManagePage(initialTabIndex: manageTabIndex);                      case 3:
                        return const UserBookingsPage();
                      case 4:
                        return const SettingsPage();
                      default:
                        return const HomePage();
                    }
                  } else {
                    // Regular user navigation
                    switch (index) {
                      case 0:
                        return const HomePage();
                      case 1:
                        return const AvailableRoomsPage();                      case 2:
                        return const UserBookingsPage();
                      case 3:
                        return const SettingsPage();
                      default:
                        return const HomePage();
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}