import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String classId;
  final String userId;
  final String bookingId;
  final double rating;
  final String comment;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ReviewModel({
    required this.id,
    required this.classId,
    required this.userId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReviewModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      userId: data['userId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'userId': userId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      userId: map['userId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }
} 