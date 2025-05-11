import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EaseClass',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
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

  final List<Widget> _pages = [
    const HomePage(),
    const AvailableRoomsPage(),
    const ProgressPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Available Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
