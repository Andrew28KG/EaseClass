import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart'; // Add required import for @required

// Model for Event data
class EventModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  // Factory constructor for creating an EventModel from a Firestore document
  factory EventModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return EventModel(
      id: doc.id,
      title: data?['title'] ?? '',
      description: data?['content'] ?? '',
      imageUrl: data?['imageUrl'] ?? '',
    );
  }

  // Method to convert EventModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': description,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(), // Optional: add a timestamp
    };
  }
}

// Service class for interacting with Event data in Firestore
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events'; // Firestore collection name

  // Get all events as a stream (for real-time updates in UI)
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false) // Order by creation time
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromDocument(doc)).toList());
  }

  // Get all events as a Future (for fetching data once, e.g., for admin editing)
  Future<List<EventModel>> getAllEvents() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) => EventModel.fromDocument(doc)).toList();
    } catch (e) {
      print('Error getting all events: $e');
      return [];
    }
  }

  // Add a new event
  Future<void> addEvent(String title, String description, String imageUrl) async {
    try {
      await _firestore.collection(_collection).add({
        'title': title,
        'content': description,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding event: $e');
    }
  }

  // Update an existing event
  Future<void> updateEvent(String eventId, String title, String description, String imageUrl) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'title': title,
        'content': description,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(), // Optional: add an update timestamp
      });
    } catch (e) {
      print('Error updating event: $e');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).delete();
    } catch (e) {
      print('Error deleting event: $e');
    }
  }
} 