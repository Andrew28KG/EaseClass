import 'package:flutter/material.dart';
import 'booked_rooms_page.dart';
import 'booking_history_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar to prevent double headers
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48), // Just for the tab bar height
        child: Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Current Bookings'),
              Tab(text: 'History'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BookedRoomsPage(),
          BookingHistoryPage(),
        ],
      ),
    );
  }
}