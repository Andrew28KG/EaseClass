import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';
import 'pages/home_page.dart';
import 'pages/available_rooms_page.dart';
import 'pages/room_detail_page.dart';
import 'pages/progress_page.dart';
import 'pages/progress_detail_page.dart';
import 'pages/settings_page.dart';
import 'pages/booking_confirmation_page.dart';
import 'pages/rating_page.dart';
import 'pages/user_login_page.dart';
import 'pages/admin_login_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'services/database_initializer.dart';

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
  
  runApp(const MyApp());
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
          ),
        ),
        
        cardTheme: CardTheme(
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
      ),
      home: const UserLoginPage(),
      routes: {
        '/user-login': (context) => const UserLoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/home': (context) => const MainPage(),
        '/room-detail': (context) => const RoomDetailPage(),
        '/booking-confirmation': (context) => const BookingConfirmationPage(),
        '/progress-detail': (context) => const ProgressDetailPage(),
        '/rating': (context) => const RatingPage(),
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
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for arguments when dependencies change (including first build)
    _checkForTabArguments();
  }

  void _checkForTabArguments() {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    // Only handle numerical tab indices, nothing else
    if (args != null && args is int && args >= 0 && args < _navigatorKeys.length) {
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
  
  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // If user taps on the active tab, try to pop to root
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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
          }

          // Default page for each tab
          return MaterialPageRoute(
            builder: (context) {
              switch (index) {
                case 0:
                  return const HomePage();
                case 1:
                  return const AvailableRoomsPage();
                case 2:
                  return const ProgressPage();
                case 3:
                  return const SettingsPage();
                default:
                  return const HomePage();
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Try to pop the current navigator first
        final NavigatorState currentNavigator = _navigatorKeys[_selectedIndex].currentState!;
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
        body: Stack(
          children: [
            _buildPageNavigator(0),
            _buildPageNavigator(1),
            _buildPageNavigator(2),
            _buildPageNavigator(3),
          ],
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
            child: BottomNavigationBar(
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
                const BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history_rounded),
                  label: 'Progress',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
