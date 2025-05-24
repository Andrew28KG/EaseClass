import 'package:flutter/material.dart';
import 'user_management.dart';
import 'class_management.dart';
import 'room_management.dart';

class ManagePage extends StatefulWidget {
  final int? initialTabIndex;
  
  const ManagePage({Key? key, this.initialTabIndex}) : super(key: key);

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
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
              Tab(text: 'Users'),
              Tab(text: 'Classes'),
              Tab(text: 'Rooms'),
            ],
          ),
        ),
      ),body: TabBarView(
        controller: _tabController,
        children: [
          const UserManagementPage(),
          const ClassManagementPage(),
          const RoomManagementPage(),
        ],
      ),
    );
  }
}