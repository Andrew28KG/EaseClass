import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../models/class_model.dart';
import '../models/faq_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _roomsCollection = FirebaseFirestore.instance.collection('rooms');
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance.collection('bookings');
  final CollectionReference _ratingsCollection = FirebaseFirestore.instance.collection('ratings');
  final CollectionReference _classesCollection = FirebaseFirestore.instance.collection('classes');
  final CollectionReference _faqsCollection = FirebaseFirestore.instance.collection('faqs');

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
  Future<bool> updateRoomAvailability(String roomId, bool isAvailable) async {
    try {
      await _roomsCollection.doc(roomId).update({
        'isAvailable': isAvailable,
      });
      return true;
    } catch (e) {
      print('Error updating room availability: $e');
      return false;
    }
  }
  
  Future<List<RoomModel>> getRooms() async {
    try {
      final QuerySnapshot snapshot = await _roomsCollection.get();
      return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting rooms: $e');
      return [];
    }
  }
  
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

  Future<void> addRoom(RoomModel room) async {
    try {
      await _roomsCollection.doc(room.id).set(room.toMap());
    } catch (e) {
      print('Error adding room: $e');
      rethrow; // Re-throw the error for the caller to handle
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _roomsCollection.doc(roomId).delete();
    } catch (e) {
      print('Error deleting room: $e');
      rethrow; // Re-throw the error for the caller to handle
    }
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> updatedData) async {
    try {
      await _roomsCollection.doc(roomId).update(updatedData);
    } catch (e) {
      print('Error updating room: $e');
      rethrow; // Re-throw the error for the caller to handle
    }
  }

  // Stream for real-time room updates
  Stream<List<RoomModel>> getRoomsStream() {
    return _roomsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    });
  }

  // Class operations
  Future<List<ClassModel>> getAvailableClasses() async {
    try {
      final QuerySnapshot snapshot = await _classesCollection
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting available classes: $e');
      return [];
    }
  }

  Future<ClassModel?> getClassDetails(String classId) async {
    try {
      final DocumentSnapshot doc = await _classesCollection.doc(classId).get();
      if (doc.exists) {
        return ClassModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting class details: $e');
      return null;
    }
  }

  Future<List<ClassModel>> filterClasses({
    String? building,
    int? minCapacity,
    List<String>? requiredFeatures,
    bool? onlyAvailable,
  }) async {
    try {
      Query query = _classesCollection;
      
      if (building != null) {
        query = query.where('building', isEqualTo: building);
      }
      
      if (minCapacity != null) {
        query = query.where('capacity', isGreaterThanOrEqualTo: minCapacity);
      }
      
      if (onlyAvailable != null && onlyAvailable) {
        query = query.where('isAvailable', isEqualTo: true);
      }
      
      final QuerySnapshot snapshot = await query.get();
      List<ClassModel> classes = snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
      
      // Apply feature filtering (can't be done in Firestore query directly)
      if (requiredFeatures != null && requiredFeatures.isNotEmpty) {
        classes = classes.where((classItem) {
          return requiredFeatures.every((feature) => classItem.features.contains(feature));
        }).toList();
      }
      
      return classes;
    } catch (e) {
      print('Error filtering classes: $e');
      return [];
    }
  }

  // FAQ operations
  Future<List<FAQModel>> getFAQs({String? category}) async {
    try {
      Query query = _faqsCollection.where('isActive', isEqualTo: true);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      query = query.orderBy('order');
      
      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => FAQModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting FAQs: $e');
      return [];
    }
  }

  // Stream for real-time FAQ updates
  Stream<List<FAQModel>> getFAQsStream({String? category}) {
    Query query = _faqsCollection.where('isActive', isEqualTo: true);
    
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    
    query = query.orderBy('order'); // Assuming 'order' field exists for sorting, or use 'createdAt'
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FAQModel.fromFirestore(doc)).toList();
    });
  }

  Future<List<String>> getFAQCategories() async {
    try {
      final QuerySnapshot snapshot = await _faqsCollection
          .where('isActive', isEqualTo: true)
          .get();
      
      Set<String> categories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        categories.add(data['category'] ?? 'General');
      }
      
      return categories.toList();
    } catch (e) {
      print('Error getting FAQ categories: $e');
      return [];
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

  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': status,
      });
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  Future<List<BookingModel>> getUserBookings({String? status}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    try {
      Query query = _bookingsCollection.where('userId', isEqualTo: currentUser.uid);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      final QuerySnapshot snapshot = await query.get();
      
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

  Future<List<BookingModel>> getCompletedBookings() async {
    return getUserBookings(status: 'completed');
  }

  Future<List<BookingModel>> getOngoingBookings() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    try {
      final QuerySnapshot snapshot = await _bookingsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['pending', 'upcoming'])
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<BookingModel> bookings = [];
      for (final doc in snapshot.docs) {
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
      print('Error getting ongoing bookings: $e');
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

  Future<List<Map<String, dynamic>>> getClassRatings(String classId) async {
    try {
      final QuerySnapshot snapshot = await _ratingsCollection
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting class ratings: $e');
      return [];
    }
  }
} 