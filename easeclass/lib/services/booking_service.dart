import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'bookings';

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
}