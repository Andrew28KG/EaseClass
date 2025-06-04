import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'bookings';
  final String _ratingsCollection = 'ratings';
  final String _classesCollection = 'classes';

  // Get all bookings for admin
  Stream<List<BookingModel>> getAllBookings() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) async {
          final bookings = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              // Get class details
              final classDoc = await _firestore.collection(_classesCollection).doc(data['roomId']).get();
              final classData = classDoc.data() ?? {};
              
              // Get user details
              Map<String, dynamic> userDetails = {};
              if (data['userId'] != null) {
                final userDoc = await _firestore.collection('users').doc(data['userId']).get();
                if (userDoc.exists) {
                  userDetails = userDoc.data() ?? {};
                }
              }

              return BookingModel.fromMap({
                'id': doc.id,
                ...data,
                'roomDetails': {
                  'name': classData['name'] ?? 'Class ${data['roomId']}',
                  'building': classData['building'] ?? '-',
                  'floor': classData['floor']?.toString() ?? '-',
                  'capacity': classData['capacity'] ?? 0,
                  'features': classData['features'] ?? [],
                },
                'userDetails': {
                   'name': userDetails['displayName'] ?? 'Anonymous',
                   'email': userDetails['email'] ?? '-',
                } // Include user details
              });
            }),
          );
          return bookings;
        })
        .asyncMap((future) => future);
  }

  // Get bookings by status for admin
  Stream<List<BookingModel>> getBookingsByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) async {
          final bookings = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              // Get class details
              final classDoc = await _firestore.collection(_classesCollection).doc(data['roomId']).get();
              final classData = classDoc.data() ?? {};

              // Get user details
              Map<String, dynamic> userDetails = {};
              if (data['userId'] != null) {
                final userDoc = await _firestore.collection('users').doc(data['userId']).get();
                if (userDoc.exists) {
                  userDetails = userDoc.data() ?? {};
                }
              }
              
              return BookingModel.fromMap({
                'id': doc.id,
                ...data,
                'roomDetails': {
                  'name': classData['name'] ?? 'Class ${data['roomId']}',
                  'building': classData['building'] ?? '-',
                  'floor': classData['floor']?.toString() ?? '-',
                  'capacity': classData['capacity'] ?? 0,
                  'features': classData['features'] ?? [],
                },
                 'userDetails': {
                   'name': userDetails['displayName'] ?? 'Anonymous',
                   'email': userDetails['email'] ?? '-',
                } // Include user details
              });
            }),
          );
          return bookings;
        })
        .asyncMap((future) => future);
  }

  // Get user bookings
  Stream<List<BookingModel>> getUserBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) async {
          final bookings = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              // Get class details
              final classDoc = await _firestore.collection(_classesCollection).doc(data['roomId']).get();
              final classData = classDoc.data() ?? {};
              
              return BookingModel.fromMap({
                'id': doc.id,
                ...data,
                'roomDetails': {
                  'name': classData['name'] ?? 'Class ${data['roomId']}',
                  'building': classData['building'] ?? '-',
                  'floor': classData['floor']?.toString() ?? '-',
                  'capacity': classData['capacity'] ?? 0,
                  'features': classData['features'] ?? [],
                },
              });
            }),
          );
          return bookings;
        })
        .asyncMap((future) => future);
  }

  // Get user bookings by status
  Stream<List<BookingModel>> getUserBookingsByStatus(String status) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) async {
          final bookings = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              // Get class details
              final classDoc = await _firestore.collection(_classesCollection).doc(data['roomId']).get();
              final classData = classDoc.data() ?? {};
              
              return BookingModel.fromMap({
                'id': doc.id,
                ...data,
                'roomDetails': {
                  'name': classData['name'] ?? 'Class ${data['roomId']}',
                  'building': classData['building'] ?? '-',
                  'floor': classData['floor']?.toString() ?? '-',
                  'capacity': classData['capacity'] ?? 0,
                  'features': classData['features'] ?? [],
                },
              });
            }),
          );
          return bookings;
        })
        .asyncMap((future) => future);
  }

  // Helper to check if user has enabled notifications for a specific type
  Future<bool> _isNotificationEnabled(String userId, String type) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return true; // Default to true if settings don't exist
      
      final data = userDoc.data();
      if (data == null) return true;
      
      final notifications = data['notifications'] as Map<String, dynamic>?;
      if (notifications == null) return true;
      
      // Map notification types to settings
      switch (type) {
        case 'pending':
          return notifications['pendingApproval'] ?? true;
        case 'approved':
          return notifications['approved'] ?? true;
        default:
          return true;
      }
    } catch (e) {
      print('Error checking notification settings: $e');
      return true; // Default to true if there's an error
    }
  }

  // Helper to create a notification
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String bookingId,
  }) async {
    // Check if notifications are enabled for this type
    final isEnabled = await _isNotificationEnabled(userId, type);
    if (!isEnabled) return; // Don't create notification if disabled

    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'bookingId': bookingId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // Create a new booking
  Future<String> createBooking(BookingModel booking) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final bookingData = booking.toMap();
    bookingData['userId'] = user.uid;
    bookingData['status'] = bookingData['status'] ?? 'pending';
    bookingData['createdAt'] = FieldValue.serverTimestamp();
    bookingData.remove('id');

    final docRef = await _firestore.collection(_collection).add(bookingData);

    // Create notification for pending booking
    await _createNotification(
      userId: user.uid,
      title: 'Booking Submitted',
      body: 'Your booking request for ${booking.roomDetails['name']} is pending approval.',
      type: 'pending',
      bookingId: docRef.id,
    );

    return docRef.id;
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': status,
    });

    // Fetch booking to get userId and room name
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    final data = doc.data();
    if (data == null) return;
    final userId = data['userId'] ?? '';
    final roomName = data['roomDetails']?['name'] ?? 'the class';

    if (status == 'approved') {
      await _createNotification(
        userId: userId,
        title: 'Booking Approved',
        body: 'Your booking for $roomName has been approved.',
        type: 'approved',
        bookingId: bookingId,
      );
    } else if (status == 'rejected') {
      await _createNotification(
        userId: userId,
        title: 'Booking Rejected',
        body: 'Your booking for $roomName has been rejected.',
        type: 'rejected',
        bookingId: bookingId,
      );
    }
  }

  // Admin approve booking with optional reason
  Future<void> approveBooking(String bookingId, {String? reason}) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': 'approved',
      'adminResponseReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Ensure notification is created
    await updateBookingStatus(bookingId, 'approved');
  }

  // Admin reject booking with reason
  Future<void> rejectBooking(String bookingId, String reason) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': 'rejected',
      'adminResponseReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Ensure notification is created
    await updateBookingStatus(bookingId, 'rejected');
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'cancelled');
  }

  // Complete booking
  Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'completed');
  }

  // Get a specific booking by ID
  Future<BookingModel?> getBookingById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) {
      return null;
    }

    final data = doc.data();
    if (data == null) {
      return null;
    }

    // Get class details
    final classDoc = await _firestore.collection(_classesCollection).doc(data['roomId']).get();
    final classData = classDoc.data() ?? {};

    return BookingModel.fromMap({
      'id': doc.id,
      ...data,
      'roomDetails': {
        'name': classData['name'] ?? 'Class ${data['roomId']}',
        'building': classData['building'] ?? '-',
        'floor': classData['floor']?.toString() ?? '-',
        'capacity': classData['capacity'] ?? 0,
        'features': classData['features'] ?? [],
      },
    });
  }

  // Check if class is available at a specific time
  Future<bool> isClassAvailable(String classId, DateTime date, String timeSlot) async {
    final formattedDate = date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    
    final conflictingBookings = await _firestore
        .collection(_collection)
        .where('roomId', isEqualTo: classId)
        .where('date', isEqualTo: formattedDate)
        .where('timeSlot', isEqualTo: timeSlot)
        .where('status', whereIn: ['pending', 'approved'])
        .get();
        
    return conflictingBookings.docs.isEmpty;
  }

  // Get all bookings for a specific class
  Stream<List<BookingModel>> getClassBookings(String classId) {
    return _firestore
        .collection(_collection)
        .where('roomId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) async {
          final bookings = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              // Get class details
              final classDoc = await _firestore.collection(_classesCollection).doc(data['roomId']).get();
              final classData = classDoc.data() ?? {};
              
              return BookingModel.fromMap({
                'id': doc.id,
                ...data,
                'roomDetails': {
                  'name': classData['name'] ?? 'Class ${data['roomId']}',
                  'building': classData['building'] ?? '-',
                  'floor': classData['floor']?.toString() ?? '-',
                  'capacity': classData['capacity'] ?? 0,
                  'features': classData['features'] ?? [],
                },
              });
            }),
          );
          return bookings;
        })
        .asyncMap((future) => future);
  }

  // Get all bookings for a specific room
  Stream<List<BookingModel>> getRoomBookings(String roomId) {
    return _firestore
        .collection(_collection)
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return BookingModel.fromMap({
                  'id': doc.id,
                  ...data,
                });
              })
              .toList();
        });
  }

  // Get recent reviews
  Future<List<Map<String, dynamic>>> getRecentReviews({int limit = 5}) async {
    try {
      // Get reviews with comments
      final QuerySnapshot reviewsSnapshot = await _firestore
          .collection(_ratingsCollection)
          .where('comment', isNull: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return [];

      List<Map<String, dynamic>> reviews = [];
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['comment'] == null || (data['comment'] as String).isEmpty) continue;
        
        // Get room details
        String roomId = data['roomId'] ?? '';
        Map<String, dynamic> roomDetails = {};
        
        if (roomId.isNotEmpty) {
          final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
          if (roomDoc.exists) {
            roomDetails = roomDoc.data() as Map<String, dynamic>;
          }
        }
        
        // Get user details
        String userId = data['userId'] ?? '';
        Map<String, dynamic> userDetails = {};
        
        if (userId.isNotEmpty) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            userDetails = userDoc.data() as Map<String, dynamic>;
          }
        }

        reviews.add({
          'id': doc.id,
          ...data,
          'room': roomDetails,
          'user': userDetails
        });
      }

      return reviews;
    } catch (e) {
      print('Error getting recent reviews: $e');
      return [];
    }
  }
  
  // Get top booked classes
  Future<List<Map<String, dynamic>>> getTopBookedClasses({int limit = 5}) async {
    try {
      // First get all completed bookings
      final QuerySnapshot bookingsSnapshot = await _firestore
          .collection(_collection)
          .where('status', whereIn: ['completed', 'approved'])
          .get();
      
      if (bookingsSnapshot.docs.isEmpty) return [];
      
      // Count bookings per class
      Map<String, int> classBookingCounts = {};
      
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final classId = data['classId'] ?? '';
        
        if (classId.isNotEmpty) {
          if (classBookingCounts.containsKey(classId)) {
            classBookingCounts[classId] = (classBookingCounts[classId] ?? 0) + 1;
          } else {
            classBookingCounts[classId] = 1;
          }
        }
      }
      
      // Sort by booking count
      var sortedEntries = classBookingCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Get top classes with details
      List<Map<String, dynamic>> topClasses = [];
      
      for (var i = 0; i < limit && i < sortedEntries.length; i++) {
        final classId = sortedEntries[i].key;
        final bookingCount = sortedEntries[i].value;
        
        final classDoc = await _firestore.collection(_classesCollection).doc(classId).get();
        
        if (classDoc.exists) {
          final classData = classDoc.data() as Map<String, dynamic>;
          topClasses.add({
            'id': classDoc.id,
            ...classData,
            'bookingCount': bookingCount
          });
        }
      }
      
      return topClasses;
    } catch (e) {
      print('Error getting top booked classes: $e');
      return [];
    }
  }

  // Get room booking counts
  Future<List<Map<String, dynamic>>> getTopBookedRooms({int limit = 5}) async {
    try {
      // First get all completed bookings
      final QuerySnapshot bookingsSnapshot = await _firestore
          .collection(_collection)
          .where('status', whereIn: ['completed', 'approved'])
          .get();
      
      if (bookingsSnapshot.docs.isEmpty) return [];
      
      // Count bookings per room
      Map<String, int> roomBookingCounts = {};
      
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final roomId = data['roomId'] ?? '';
        
        if (roomId.isNotEmpty) {
          if (roomBookingCounts.containsKey(roomId)) {
            roomBookingCounts[roomId] = (roomBookingCounts[roomId] ?? 0) + 1;
          } else {
            roomBookingCounts[roomId] = 1;
          }
        }
      }
      
      // Sort by booking count
      var sortedEntries = roomBookingCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Get top rooms with details
      List<Map<String, dynamic>> topRooms = [];
      
      for (var i = 0; i < limit && i < sortedEntries.length; i++) {
        final roomId = sortedEntries[i].key;
        final bookingCount = sortedEntries[i].value;
        
        final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
        
        if (roomDoc.exists) {
          final roomData = roomDoc.data() as Map<String, dynamic>;
          topRooms.add({
            'id': roomDoc.id,
            ...roomData,
            'bookingCount': bookingCount
          });
        }
      }
      
      return topRooms;
    } catch (e) {
      print('Error getting top booked rooms: $e');
      return [];
    }
  }

  // New method to get bookings for a specific room and date
  Future<List<BookingModel>> getBookingsForRoomAndDate(String roomId, String date) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('roomId', isEqualTo: roomId)
          .where('date', isEqualTo: date)
          .where('status', whereIn: ['pending', 'approved']) // Only consider pending and approved bookings
          .orderBy('time') // Order by time to process sequentially
          .get();

      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting bookings for room $roomId on $date: $e');
      return [];
    }
  }

  // New method to get bookings for a specific room
  Future<List<BookingModel>> getBookingsForRoom(String roomId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('roomId', isEqualTo: roomId)
          .orderBy('createdAt', descending: true) // Optional: order by creation date
          .get();

      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting bookings for room $roomId: $e');
      return [];
    }
  }

  // Submit rating for a completed booking
  Future<void> submitRating(String bookingId, double rating) async {
    // Ensure class details are fetched using _classesCollection if needed here
    // ... existing code ...
  }
}