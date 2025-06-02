import 'package:flutter/material.dart';
import 'admin_booking_progress_page.dart';
import 'admin_booking_history_page.dart';
import 'booking_management_page.dart';
import '../../theme/app_colors.dart';

class AdminBookingsPage extends StatefulWidget {
  final bool showAppBar;
  
  const AdminBookingsPage({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Updated to 3 tabs
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.showAppBar ? AppBar(
        elevation: 0,
        title: const Text('Bookings'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Management'),
            Tab(text: 'Progress'),
            Tab(text: 'History'),
          ],
        ),
      ) : null,
      body: TabBarView(
        controller: _tabController,
        children: const [
          BookingManagementPage(),
          AdminBookingProgressPage(),
          AdminBookingHistoryPage(),
        ],
      ),
    );
  }
}
