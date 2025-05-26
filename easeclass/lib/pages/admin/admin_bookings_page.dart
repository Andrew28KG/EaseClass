import 'package:flutter/material.dart';
import 'admin_booked_rooms_page.dart';
import 'admin_booking_progress_page.dart';
import 'admin_booking_history_page.dart';

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
      body: Column(
        children: [
          // Solid orange header with title (square)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 32, bottom: 16),
            color: Colors.orange,
            child: const Center(
              child: Text(
                'Bookings Management',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          // TabBar for 3 sections with curved bottom
          Container(
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Approval'),
                Tab(text: 'On-going'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          // TabBarView content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const AdminBookedRoomsPage(),
                const AdminBookingProgressPage(),
                const AdminBookingHistoryPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
