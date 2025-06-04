import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification_model.dart';
import '../../models/booking_model.dart';
import 'user_history_booking_detail_page.dart';
import 'user_booking_detail_page.dart';
import '../../utils/navigation_helper.dart';

class UserNotificationsPage extends StatefulWidget {
  const UserNotificationsPage({Key? key}) : super(key: key);

  @override
  State<UserNotificationsPage> createState() => _UserNotificationsPageState();
}

class _UserNotificationsPageState extends State<UserNotificationsPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _markedRead = false;

  @override
  void dispose() {
    _markedRead = false;
    super.dispose();
  }

  Stream<List<NotificationModel>> _userNotificationsStream() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  Future<void> _markAllNotificationsRead(List<NotificationModel> notifications) async {
    final unread = notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await FirebaseFirestore.instance.collection('notifications').doc(n.id).update({'isRead': true});
    }
  }

  Future<void> _openBookingDetail(BuildContext context, String bookingId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
      useRootNavigator: true,
    );
    try {
      final doc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
      if (!doc.exists) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking not found.')));
        return;
      }
      final booking = BookingModel.fromFirestore(doc);
      Navigator.of(context, rootNavigator: true).pop(); // Close loading FIRST
      
      // First navigate to the bookings tab
      NavigationHelper.navigateToBookings(context);
      
      // Then navigate to the booking details
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserBookingDetailPage(
              booking: booking,
              onBookingUpdated: () {
                print('Booking updated from notification detail page');
              },
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading booking.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to home tab
            NavigationHelper.navigateToTab(context, 0);
          },
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _userNotificationsStream(),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          // Mark all as read only once per page open
          final hasUnread = notifications.any((n) => !n.isRead);
          if (!_markedRead && hasUnread) {
            _markedRead = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _markAllNotificationsRead(notifications);
            });
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                leading: Icon(
                  n.type == 'approved'
                      ? Icons.check_circle
                      : n.type == 'rejected'
                          ? Icons.cancel
                          : Icons.info,
                  color: n.type == 'approved'
                      ? Colors.green
                      : n.type == 'rejected'
                          ? Colors.red
                          : Colors.blue,
                ),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.body),
                    if (n.bookingId.isNotEmpty)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('bookings').doc(n.bookingId).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          final date = data['date'] ?? '';
                          final time = data['time'] ?? '';
                          final room = (data['roomDetails'] != null && data['roomDetails']['name'] != null)
                              ? data['roomDetails']['name']
                              : '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Class: $room\nDate: $date\nTime: $time',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                trailing: n.isRead ? null : const Icon(Icons.fiber_manual_record, color: Colors.blue, size: 12),
                onTap: n.bookingId.isNotEmpty
                    ? () => _openBookingDetail(context, n.bookingId)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
} 