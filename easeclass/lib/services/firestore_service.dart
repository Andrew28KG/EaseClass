import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/faq_model.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _classesCollection = FirebaseFirestore.instance.collection('classes');
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance.collection('bookings');
  final CollectionReference _reviewsCollection = FirebaseFirestore.instance.collection('reviews');
  final CollectionReference _faqsCollection = FirebaseFirestore.instance.collection('faqs');
  final CollectionReference _eventsCollection = FirebaseFirestore.instance.collection('events');

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

  // Class operations
  Future<List<ClassModel>> getClasses() async {
    try {
      final QuerySnapshot snapshot = await _classesCollection.get();
      return snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting classes: $e');
      return [];
    }
  }

  Stream<List<ClassModel>> getClassesStream() {
    return _classesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
    });
  }

  Future<bool> addClass(ClassModel classModel) async {
    try {
      await _classesCollection.doc(classModel.id).set(classModel.toMap());
      return true;
    } catch (e) {
      print('Error adding class: $e');
      return false;
    }
  }

  Future<bool> deleteClass(String classId) async {
    try {
      await _classesCollection.doc(classId).delete();
      return true;
    } catch (e) {
      print('Error deleting class: $e');
      return false;
    }
  }

  Future<bool> updateClassAvailability(String classId, bool isAvailable) async {
    try {
      await _classesCollection.doc(classId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating class availability: $e');
      return false;
    }
  }

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

  Future<bool> updateClass(String classId, Map<String, dynamic> data) async {
    try {
      await _classesCollection.doc(classId).update(data);
      return true;
    } catch (e) {
      print('Error updating class: $e');
      return false;
    }
  }

  // Booking operations
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final QuerySnapshot snapshot = await _bookingsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  Future<bool> createBooking(BookingModel booking) async {
    try {
      await _bookingsCollection.doc(booking.id).set(booking.toMap());
      return true;
    } catch (e) {
      print('Error creating booking: $e');
      return false;
    }
  }

  // Review operations
  Future<List<ReviewModel>> getClassReviews(String classId) async {
    try {
      final QuerySnapshot snapshot = await _reviewsCollection
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting class reviews: $e');
      return [];
    }
  }

  Future<bool> submitRating({
    required String bookingId,
    required String roomId,
    required double rating,
    String? comment,
  }) async {
    try {
      // Get the current user
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Create a new review document
      final reviewId = _reviewsCollection.doc().id;
      final now = Timestamp.now();
      
      final review = ReviewModel(
        id: reviewId,
        classId: roomId,
        userId: currentUser.id,
        bookingId: bookingId,
        rating: rating,
        comment: comment ?? '',
        createdAt: now,
        updatedAt: now,
      );

      // Add the review
      await _reviewsCollection.doc(reviewId).set(review.toMap());

      // Update the booking with the rating
      await _bookingsCollection.doc(bookingId).update({
        'rating': rating,
        'reviewId': reviewId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the class rating
      final classDoc = await _classesCollection.doc(roomId).get();
      if (classDoc.exists) {
        final classData = classDoc.data() as Map<String, dynamic>;
        final currentRating = (classData['rating'] ?? 0.0).toDouble();
        final totalRatings = (classData['totalRatings'] ?? 0) + 1;
        final newRating = ((currentRating * (totalRatings - 1)) + rating) / totalRatings;
        
        await _classesCollection.doc(roomId).update({
          'rating': newRating,
          'totalRatings': totalRatings,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error submitting rating: $e');
      return false;
    }
  }

  Future<bool> addReview(ReviewModel review) async {
    try {
      await _reviewsCollection.doc(review.id).set(review.toMap());
      
      // Update class rating
      final classDoc = await _classesCollection.doc(review.classId).get();
      if (classDoc.exists) {
        final classData = classDoc.data() as Map<String, dynamic>;
        final currentRating = (classData['rating'] ?? 0.0).toDouble();
        final totalRatings = (classData['totalRatings'] ?? 0) + 1;
        final newRating = ((currentRating * (totalRatings - 1)) + review.rating) / totalRatings;
        
        await _classesCollection.doc(review.classId).update({
          'rating': newRating,
          'totalRatings': totalRatings,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  // Event operations
  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      final QuerySnapshot snapshot = await _eventsCollection
          .where('status', isEqualTo: 'upcoming')
          .where('startDate', isGreaterThan: Timestamp.now())
          .orderBy('startDate')
          .get();
      
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting upcoming events: $e');
      return [];
    }
  }

  Future<bool> createEvent(EventModel event) async {
    try {
      await _eventsCollection.doc(event.id).set(event.toMap());
      return true;
    } catch (e) {
      print('Error creating event: $e');
      return false;
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

  Stream<List<FAQModel>> getFAQsStream() {
    return _faqsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => FAQModel.fromFirestore(doc)).toList();
        });
  }
} 