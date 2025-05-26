import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
// Admin pages
import 'admin_dashboard.dart';
import 'manage_page.dart'; // Now in admin folder
import 'admin_bookings_page.dart'; // Use admin's BookingsPage with Progress tab
import 'admin_settings_page.dart';
import 'package:provider/provider.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({Key? key}) : super(key: key);

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final List<String> _titles = ['Dashboard', 'Management', 'Bookings', 'Profile'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Ensure the index is valid for the page controller
    if (index < _titles.length) {
      setState(() {
        _selectedIndex = index;
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return WillPopScope(
      // Prevent back button navigation to user pages
      onWillPop: () async => false,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },          children: [
            const AdminDashboard(showTabs: false), // Use AdminDashboard without duplicate tabs
            const ManagePage(),
            const AdminBookingsPage(), // Use admin's BookingsPage with Progress tab
            const AdminSettingsPage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.secondary, // Use secondary color for admin pages
          unselectedItemColor: AppColors.darkGrey,          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
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