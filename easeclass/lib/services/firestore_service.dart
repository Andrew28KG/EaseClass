import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference _roomsCollection = FirebaseFirestore.instance.collection('rooms');
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance.collection('bookings');
  final CollectionReference _ratingsCollection = FirebaseFirestore.instance.collection('ratings');

  // Room operations
  Future<List<Map<String, dynamic>>> getAvailableRooms() async {
    try {
      final QuerySnapshot snapshot = await _roomsCollection
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting available rooms: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getRoomDetails(String roomId) async {
    try {
      final DocumentSnapshot doc = await _roomsCollection.doc(roomId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
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
    required String userId,
    required String date,
    required String time,
    required String purpose,
  }) async {
    try {
      final DocumentReference docRef = await _bookingsCollection.add({
        'roomId': roomId,
        'userId': userId,
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

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final QuerySnapshot snapshot = await _bookingsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
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
    try {
      await _ratingsCollection.add({
        'bookingId': bookingId,
        'roomId': roomId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
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