import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  
  int _studentCount = 0;
  int _teacherCount = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
    Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final querySnapshot = await _firestore.collection('users').get();
      
      if (mounted) {
        final allUsers = querySnapshot.docs.map((doc) {
          return UserModel.fromFirestore(doc);
        }).toList();
        
        // Filter to only show students and teachers (exclude admins)
        final filteredUsers = allUsers.where((user) => 
          user.role == 'student' || user.role == 'teacher'
        ).toList();
          // Calculate statistics (only for students and teachers)
        _studentCount = filteredUsers.where((user) => user.role == 'student').length;
        _teacherCount = filteredUsers.where((user) => user.role == 'teacher').length;
        _totalUsers = filteredUsers.length; // Total only includes students and teachers
        
        setState(() {
          _users = filteredUsers;
          _filteredUsers = filteredUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      // Populate with dummy data
      _populateDummyData();
      setState(() => _isLoading = false);
    }
  }
    void _populateDummyData() {
    final dummyUsers = [
      UserModel(
        id: '1',
        email: 'john.doe@example.com',
        role: 'student',
        displayName: 'John Doe',
        createdAt: Timestamp.fromDate(DateTime(2023, 5, 15)),
      ),
      UserModel(
        id: '2',
        email: 'jane.smith@example.com',
        role: 'teacher',
        displayName: 'Jane Smith',
        createdAt: Timestamp.fromDate(DateTime(2023, 4, 20)),
      ),
      UserModel(
        id: '4',
        email: 'sara.wilson@example.com',
        role: 'student',
        displayName: 'Sara Wilson',
        createdAt: Timestamp.fromDate(DateTime(2023, 6, 5)),
      ),
    ];
      // Only count students and teachers
    _studentCount = dummyUsers.where((user) => user.role == 'student').length;
    _teacherCount = dummyUsers.where((user) => user.role == 'teacher').length;
    _totalUsers = dummyUsers.length; // Total only includes students and teachers
    
    _users = dummyUsers;
    _filteredUsers = dummyUsers;
  }
  
  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
      return;
    }
    
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) => 
        (user.displayName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        user.email.toLowerCase().contains(lowercaseQuery) ||
        user.role.toLowerCase().contains(lowercaseQuery)
      ).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button navigation
      child: Scaffold(
        body: Column(
          children: [
            _buildSearchBar(),
            _buildStatistics(),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : _buildUsersList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _filterUsers('');
                },
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: _filterUsers,
      ),
    );
  }
  
  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),          Row(
            children: [
              _statisticItem(
                'Students',
                _studentCount.toString(),
                Colors.blue.shade100,
                Icons.school,
              ),
              _statisticItem(
                'Teachers',
                _teacherCount.toString(),
                Colors.green.shade100,
                Icons.person,
              ),
              _statisticItem(
                'Total',
                _totalUsers.toString(),
                Colors.purple.shade100,
                Icons.group,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _statisticItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.withOpacity(0.8)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUsersList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorForRole(user.role),
              child: user.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.photoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _getIconForRole(user.role);
                      },
                    ),
                  )
                : _getIconForRole(user.role),
            ),
            title: Text(user.displayName ?? user.email.split('@').first),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text(
                  'Role: ${_capitalizeFirst(user.role)} | Joined: ${_formatDate(user.createdAt.toDate())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.history, color: Colors.blue),
              tooltip: 'View Booking History',
              onPressed: () => _showBookingHistory(user),
            ),
            isThreeLine: true,
            onTap: () => _showUserDetails(user),
          ),
        );
      },
    );
  }
    // User actions removed - no longer supporting edit/delete functionality
  
  Color _getColorForRole(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange.shade200;
      case 'teacher':
        return Colors.green.shade200;
      case 'student':
      default:
        return Colors.blue.shade200;
    }
  }
  
  Widget _getIconForRole(String role) {
    IconData iconData;
    switch (role) {
      case 'admin':
        iconData = Icons.admin_panel_settings;
        break;
      case 'teacher':
        iconData = Icons.school;
        break;
      case 'student':
      default:
        iconData = Icons.person;
    }
    return Icon(iconData, color: Colors.white);
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showBookingHistory(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getColorForRole(user.role),
                    child: _getIconForRole(user.role),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.displayName ?? 'User'} - Booking History',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<BookingModel>>(
                  future: _getUserBookings(user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading bookings: ${snapshot.error}',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      );
                    }
                    
                    final bookings = snapshot.data ?? [];
                    
                    if (bookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No booking history found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      itemCount: bookings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _buildBookingCard(booking);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildBookingCard(BookingModel booking) {
    Color statusColor;
    IconData statusIcon;
    
    switch (booking.status) {
      case 'upcoming':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.roomDetails?['name'] ?? 'Room ${booking.roomId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _capitalizeFirst(booking.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (booking.purpose.isNotEmpty)
              Text(
                'Purpose: ${booking.purpose}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            const SizedBox(height: 4),
            Text(
              'Date: ${booking.date}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'Time: ${booking.time}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (booking.rating != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Rating: ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  ...List.generate(5, (index) {
                    return Icon(
                      index < (booking.rating?.round() ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  Future<List<BookingModel>> _getUserBookings(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return BookingModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error loading user bookings: $e');
      // Return dummy data for demonstration
      return [
        BookingModel(
          id: '1',
          userId: userId,
          roomId: 'room1',
          date: '2024-${DateTime.now().month.toString().padLeft(2, '0')}-${(DateTime.now().day - 7).toString().padLeft(2, '0')}',
          time: '10:00 - 12:00',
          status: 'completed',
          purpose: 'Team meeting',
          createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
          roomDetails: {'name': 'Conference Room A'},
        ),
        BookingModel(
          id: '2',
          userId: userId,
          roomId: 'room2',
          date: '2024-${DateTime.now().month.toString().padLeft(2, '0')}-${(DateTime.now().day - 3).toString().padLeft(2, '0')}',
          time: '14:00 - 15:00',
          status: 'cancelled',
          purpose: 'Study session',
          createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          roomDetails: {'name': 'Study Room B'},
        ),
      ];
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getColorForRole(user.role),
                    child: user.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _getIconForRole(user.role);
                            },
                          ),
                        )
                      : _getIconForRole(user.role),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorForRole(user.role),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _capitalizeFirst(user.role),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow('Email', user.email),
              _detailRow('ID', user.id),
              _detailRow('Created', _formatDate(user.createdAt.toDate())),
              if (user.preferences != null && user.preferences!.isNotEmpty)
                _detailRow('Preferences', user.preferences.toString()),              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('View Booking History'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showBookingHistory(user);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
    // Add user dialog removed - no longer supporting user creation from admin interface
  
  // Edit user dialog removed - no longer supporting user editing from admin interface
  
  // Delete user dialog removed - no longer supporting user deletion from admin interface
}
