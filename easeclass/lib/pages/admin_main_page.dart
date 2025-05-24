import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'manage_page.dart';
import 'bookings_page.dart';
import 'admin_settings_page.dart'; // Changed to admin-specific settings
import 'admin_dashboard.dart';
import 'admin_available_rooms_page.dart'; // Import the new AdminAvailableRoomsPage
import '../theme/app_colors.dart'; // Import AppColors
import 'package:provider/provider.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({Key? key}) : super(key: key);

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final List<String> _titles = ['Dashboard', 'Available Rooms', 'Management', 'Bookings', 'Profile'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return WillPopScope(
      // Prevent back button navigation to user pages
      onWillPop: () async => false,      child: Scaffold(        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          automaticallyImplyLeading: false, // Remove back button
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Completely rectangular shape
          ),
          centerTitle: true,
          backgroundColor: AppColors.secondary, // Use secondary color for admin pages
          foregroundColor: Colors.white,
          actions: [
            // Add dashboard access button if not on dashboard
            if (_selectedIndex != 0)
              IconButton(
                icon: const Icon(Icons.dashboard),
                tooltip: 'Go to Dashboard',
                onPressed: () {
                  _onItemTapped(0); // Navigate to dashboard tab
                },
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (shouldLogout == true) {
                  await authService.signOut();
                  if (mounted) {
                    // Navigate to admin login page and clear all routes
                    Navigator.of(context).pushNamedAndRemoveUntil('/admin-login', (route) => false);
                  }
                }
              },
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },          children: [
            const AdminDashboard(showTabs: false), // Use AdminDashboard without duplicate tabs
            const AdminAvailableRoomsPage(), // Use the new AdminAvailableRoomsPage
            const ManagePage(),
            const BookingsPage(),
            const AdminSettingsPage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room_outlined),
              activeIcon: Icon(Icons.meeting_room_rounded),
              label: 'Available Rooms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Management',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}