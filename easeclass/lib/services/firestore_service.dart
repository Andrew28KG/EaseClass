import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _roomsCollection = FirebaseFirestore.instance.collection('rooms');
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance.collection('bookings');
  final CollectionReference _ratingsCollection = FirebaseFirestore.instance.collection('ratings');

  // User operations
  Future<UserModel?> getCurrentUser() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      final DocumentSnapshot doc = await _usersCollection.doc(currentUser.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      await _usersCollection.doc(currentUser.uid).update({
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Room operations
  Future<List<RoomModel>> getAvailableRooms() async {
    try {
      final QuerySnapshot snapshot = await _roomsCollection
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting available rooms: $e');
      return [];
    }
  }

  Future<RoomModel?> getRoomDetails(String roomId) async {
    try {
      final DocumentSnapshot doc = await _roomsCollection.doc(roomId).get();
      if (doc.exists) {
        return RoomModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting room details: $e');
      return null;
    }
  }

  // Booking operations
  Future<String?> createBooking({
    required String roomId,
    required String date,
    required String time,
    required String purpose,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      final DocumentReference docRef = await _bookingsCollection.add({
        'roomId': roomId,
        'userId': currentUser.uid,
        'date': date,
        'time': time,
        'purpose': purpose,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  Future<List<BookingModel>> getUserBookings() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    try {
      final QuerySnapshot snapshot = await _bookingsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<BookingModel> bookings = [];
      for (final doc in snapshot.docs) {
        // Get room details for each booking
        final String roomId = doc['roomId'];
        final DocumentSnapshot roomDoc = await _roomsCollection.doc(roomId).get();
        Map<String, dynamic>? roomData;
        
        if (roomDoc.exists) {
          roomData = roomDoc.data() as Map<String, dynamic>;
          roomData['id'] = roomDoc.id;
        }
        
        bookings.add(BookingModel.fromFirestore(doc, roomData: roomData));
      }
      
      return bookings;
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  // Rating operations
  Future<bool> submitRating({
    required String bookingId,
    required String roomId,
    required double rating,
    String? comment,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      // Add the rating
      await _ratingsCollection.add({
        'bookingId': bookingId,
        'roomId': roomId,
        'userId': currentUser.uid,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update the booking with the rating
      await _bookingsCollection.doc(bookingId).update({
        'rating': rating,
        'feedback': comment,
      });
      
      // Calculate new average rating for the room
      final QuerySnapshot ratingsSnapshot = await _ratingsCollection
          .where('roomId', isEqualTo: roomId)
          .get();
      
      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (final doc in ratingsSnapshot.docs) {
          totalRating += (doc.data() as Map<String, dynamic>)['rating'];
        }
        double avgRating = totalRating / ratingsSnapshot.docs.length;
        
        // Update the room with new average rating
        await _roomsCollection.doc(roomId).update({
          'rating': avgRating,
        });
      }
      
      return true;
    } catch (e) {
      print('Error submitting rating: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRoomRatings(String roomId) async {
    try {
      final QuerySnapshot snapshot = await _ratingsCollection
          .where('roomId', isEqualTo: roomId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting room ratings: $e');
      return [];
    }
  }
} 