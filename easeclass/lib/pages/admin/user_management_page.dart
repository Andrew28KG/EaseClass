import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import 'package:flutter/foundation.dart'; // Import for compute

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
        // Process data in a separate isolate using compute
        final processedData = await compute(_processUserData, querySnapshot.docs);

        setState(() {
          _users = processedData['allUsers']!;
          _filteredUsers = processedData['initialFilteredUsers']!;
          _studentCount = processedData['studentCount']!;
          _teacherCount = processedData['teacherCount']!;
          _totalUsers = processedData['totalUsers']!;
          _isLoading = false;
        });

        // Debug prints
        print('Total users loaded (including admin): ${_users.length}');
        print('Filtered users (students/teachers): ${_filteredUsers.length}');
        _users.forEach((user) {
          print('User loaded: ${user.email}, Role: ${user.role}');
        });
        _filteredUsers.forEach((user) {
           print('Filtered user: ${user.email}, Role: ${user.role}');
        });

      }
    } catch (e) {
      print('Error loading users: $e');
      // Handle error loading, maybe show an error message and keep list empty
      if (mounted) {
         setState(() {
           _users = [];
           _filteredUsers = [];
           _studentCount = 0;
           _teacherCount = 0;
           _totalUsers = 0;
           _isLoading = false;
         });
      }
    }
  }
  
  // Function to process user data in a separate isolate
  static Map<String, dynamic> _processUserData(List<QueryDocumentSnapshot> docs) {
    // Load all users (including admins) into allUsers
    final allUsers = docs.map((doc) {
      return UserModel.fromFirestore(doc);
    }).toList();

    // Initialize filtered list to show only students and teachers
    final initialFilteredUsers = allUsers.where((user) => user.role == 'student' || user.role == 'teacher').toList();

    // Calculate statistics based on the initially filtered list
    final studentCount = initialFilteredUsers.where((user) => user.role == 'student').length;
    final teacherCount = initialFilteredUsers.where((user) => user.role == 'teacher').length;
    final totalUsers = initialFilteredUsers.length; // Total of students and teachers

    return {
      'allUsers': allUsers,
      'initialFilteredUsers': initialFilteredUsers,
      'studentCount': studentCount,
      'teacherCount': teacherCount,
      'totalUsers': totalUsers,
    };
  }
  
  void _filterUsers(String query) {
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      // Always filter to show only students and teachers first (case-insensitive and trimmed)
      List<UserModel> roleFilteredUsers = _users.where((user) =>
          (user.role?.toLowerCase().trim() == 'student' || user.role?.toLowerCase().trim() == 'teacher') // Case-insensitive and trimmed role check
      ).toList();

      if (query.isEmpty) {
        // If query is empty, show all role-filtered users
        _filteredUsers = roleFilteredUsers;
      } else {
        // If query is not empty, apply text search on top of role filter (case-insensitive and trimmed)
        _filteredUsers = roleFilteredUsers.where((user) =>
            (user.displayName?.toLowerCase().trim().contains(lowercaseQuery) ?? false) ||
            user.email.toLowerCase().trim().contains(lowercaseQuery) ||
            (user.department?.toLowerCase().trim().contains(lowercaseQuery) ?? false) // Case-insensitive and trimmed department search
        ).toList();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button navigation
      child: Scaffold(
        // Removed the AppBar as it's handled by the main admin page layout
        // appBar: AppBar(
        //   title: const Text('User Management'),
        //   actions: [
        //     IconButton(
        //       icon: const Icon(Icons.add),
        //       onPressed: _showAddUserDialog,
        //       tooltip: 'Add User',
        //     ),
        //   ],
        // ),
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
        // Add the floating action button for Add User
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddUserDialog,
          tooltip: 'Add User',
          child: const Icon(Icons.add),
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
                Text('Role: ${_capitalizeFirst(user.role)}'),
                Text('Department: ${user.department ?? 'Not set'}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit User',
                  onPressed: () => _showEditUserDialog(user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete User',
                  onPressed: () => _confirmDeleteUser(user),
                ),
              ],
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
    bool _isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                        Expanded(
                          child: Text(
                            user.displayName ?? 'User Details',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                      child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            _detailRow('Full Name', user.displayName ?? 'N/A'),
                            _detailRow('NIM', user.nim ?? 'N/A'),
                            _detailRow('Email', user.email),
                            _detailRow('Department', user.department ?? 'N/A'),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Password',
                                      style: TextStyle(
                            fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                          ),
                        ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      readOnly: true,
                                      obscureText: !_isPasswordVisible,
                                      controller: TextEditingController(
                                        text: user.password ?? 'password123',
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                        suffixIconConstraints: const BoxConstraints(
                                            minWidth: 24, minHeight: 24),
                            ),
                                      style: const TextStyle(
                                        fontSize: 15,
                        ),
                    ),
                  ),
                ],
                              ),
              ),
              const SizedBox(height: 24),
              const Text(
                              'Recent Bookings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
                            FutureBuilder<List<BookingModel>>(
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
                                    child: Text(
                                      'No booking history found.',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  );
                                }

                                final displayBookings = bookings.take(5).toList();

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: displayBookings.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final booking = displayBookings[index];
                                    return _buildBookingCard(booking);
                  },
                                );
                  },
                ),
                          ],
                        ),
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
            );
          },
        );
      },
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
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
    // Add user dialog removed - no longer supporting user creation from admin interface
  
  Future<void> _showAddUserDialog() async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController nimController = TextEditingController();
    final TextEditingController passwordController = TextEditingController(text: 'password123');
    String selectedRole = 'student';
    String selectedDepartment = 'Computer Science';
    bool _isPasswordVisible = false;

    final List<String> departments = [
      'Computer Science',
      'Information Systems',
      'Information Technology',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
      'Industrial Engineering',
      'Chemical Engineering',
      'Architecture',
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'Business Administration',
      'Economics',
      'Accounting',
      'Management',
      'Psychology',
      'Law',
      'Medicine',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter user email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter full name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nimController,
                  decoration: const InputDecoration(
                    labelText: 'NIM',
                    hintText: 'Enter NIM',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Default Password',
                    hintText: 'Enter default password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                  ),
                  items: departments.map((String department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedDepartment = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty || 
                    nameController.text.isEmpty || 
                    nimController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  // First, create the user in Firebase Authentication
                  final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text,
                    password: passwordController.text,
                  );

                  // Then create the user document in Firestore
                  await _firestore.collection('users').doc(userCredential.user!.uid).set({
                    'email': emailController.text,
                    'displayName': nameController.text,
                    'nim': nimController.text,
                    'role': selectedRole,
                    'department': selectedDepartment,
                    'createdAt': FieldValue.serverTimestamp(),
                    'isAdmin': false,
                    'password': passwordController.text,
                  });

                  // Sign out the newly created user to stay in admin interface
                  await FirebaseAuth.instance.signOut(); // Explicitly sign out the new user

                  // Reload users list while still logged in as admin
                  await _loadUsers();

                  // Explicitly trigger a UI rebuild after loading
                  if (mounted) { // Check if the widget is still mounted before calling setState
                     setState(() {});
                  }

                  if (mounted) {
                    Navigator.pop(context); // Dismiss the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User added successfully')),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  String errorMessage;
                  if (e.code == 'weak-password') {
                    errorMessage = 'The password provided is too weak.';
                  } else if (e.code == 'email-already-in-use') {
                    errorMessage = 'An account already exists for that email.';
                  } else {
                    errorMessage = 'An error occurred: ${e.message}';
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding user: $e')),
                    );
                  }
                }
              },
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(UserModel user) async {
    final TextEditingController nameController = TextEditingController(text: user.displayName);
    final TextEditingController nimController = TextEditingController(text: user.nim);
    // Map 'user' role to 'student' for the dropdown
    String selectedRole = user.role == 'student' ? 'student' : user.role;
    String selectedDepartment = user.department ?? 'Computer Science';
    bool _isPasswordVisible = false;
    final TextEditingController passwordController = TextEditingController(text: user.password);

    final List<String> departments = [
      'Computer Science',
      'Information Systems',
      'Information Technology',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
      'Industrial Engineering',
      'Chemical Engineering',
      'Architecture',
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'Business Administration',
      'Economics',
      'Accounting',
      'Management',
      'Psychology',
      'Law',
      'Medicine',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter full name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nimController,
                  decoration: const InputDecoration(
                    labelText: 'NIM',
                    hintText: 'Enter NIM',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter new password (optional)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                  ),
                  items: departments.map((String department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedDepartment = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || nimController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                try {
                  // Update user document in Firestore
                  final userData = {
                    'displayName': nameController.text,
                    'nim': nimController.text,
                    'role': selectedRole,
                    'department': selectedDepartment,
                  };

                  // Only update password if a new one is provided
                  if (passwordController.text.isNotEmpty && passwordController.text != user.password) {
                    userData['password'] = passwordController.text;
                  }

                  await _firestore.collection('users').doc(user.id).update(userData);

                  // Reload users list
                  await _loadUsers();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating user: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // Method to confirm user deletion
  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete user ${user.displayName ?? user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Dismiss dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dismiss dialog
              _deleteUser(user.id); // Proceed with deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Red button for deletion
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Method to delete a user from Firestore
  void _deleteUser(String userId) async {
    try {
      // First get the user's email from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userEmail = userData?['email'];

      if (userEmail != null) {
        // Delete from Firestore
        await _firestore.collection('users').doc(userId).delete();

        // After deletion, refresh the user list
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully. Note: User may still be able to log in until their authentication account is deleted by an administrator.')),
          );
        }
      } else {
        throw Exception('User email not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }
}
