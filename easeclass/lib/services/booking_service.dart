import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'bookings';
  final String _ratingsCollection = 'ratings';
  final String _classesCollection = 'classes';

  // Get all bookings for the current user
  Stream<List<BookingModel>> getUserBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
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

  // For admin: get all bookings by status
  Stream<List<BookingModel>> getBookingsByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
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

  // Create a new booking
  Future<String> createBooking(BookingModel booking) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final bookingData = booking.toMap();
    // Ensure the booking has the current user ID
    bookingData['userId'] = user.uid;
    // Set default status if not specified
    bookingData['status'] = bookingData['status'] ?? 'pending';
    // Set creation time
    bookingData['createdAt'] = FieldValue.serverTimestamp();
    
    // Remove id field since Firestore will generate one
    bookingData.remove('id');

    final docRef = await _firestore.collection(_collection).add(bookingData);
    return docRef.id;
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin approve booking with optional reason
  Future<void> approveBooking(String bookingId, {String? reason}) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': 'approved',
      'adminResponseReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin reject booking with reason
  Future<void> rejectBooking(String bookingId, String reason) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': 'rejected',
      'adminResponseReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'cancelled');
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

    return BookingModel.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  // Check if room is available at a specific time
  Future<bool> isRoomAvailable(String roomId, DateTime date, String timeSlot) async {
    final formattedDate = date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    
    final conflictingBookings = await _firestore
        .collection(_collection)
        .where('roomId', isEqualTo: roomId)
        .where('date', isEqualTo: formattedDate)
        .where('timeSlot', isEqualTo: timeSlot)
        .where('status', whereIn: ['pending', 'approved'])
        .get();
        
    return conflictingBookings.docs.isEmpty;
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

  // Get all bookings for admin
  Stream<List<BookingModel>> getAllBookings() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
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
}