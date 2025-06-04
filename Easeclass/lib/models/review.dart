import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String classId;
  final String userId;
  final String bookingId;
  final String userName;
  final double rating;
  final String comment;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Review({
    required this.id,
    required this.classId,
    required this.userId,
    required this.bookingId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      userId: map['userId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      userName: map['userName'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      classId: data['classId'] ?? '',
      userId: data['userId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      userName: data['userName'] ?? '',
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
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 