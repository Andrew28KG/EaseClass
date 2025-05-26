import 'package:flutter/material.dart';
import 'user_management_new.dart'; // Using the fixed user management page
import 'class_management_simplified.dart'; // Using the simplified class management page
import 'content_management.dart'; // Import fixed ContentManagementPage

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
      length: 3, // Changed from 4 to 3 (removed room management)
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
      body: Column(
        children: [
          // Solid orange header with title (square)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 32, bottom: 16),
            color: Colors.orange,
            child: const Center(
              child: Text(
                'Management',
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
                Tab(icon: Icon(Icons.people), text: 'Users'),
                Tab(icon: Icon(Icons.class_), text: 'Classes'),
                Tab(icon: Icon(Icons.article), text: 'Content'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UserManagementPage(),
                ClassManagementPage(),
                ContentManagementPage(), // This is the content tab that uses ContentManagementPage
              ],
            ),
          ),
        ],
      ),
    );
  }
}