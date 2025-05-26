import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String roomId;
  final String userId;
  final String date;
  final String time;
  final String purpose;
  final String status; // 'pending', 'approved', 'rejected', 'completed', 'cancelled'
  final Timestamp createdAt;
  final double? rating;
  final String? feedback;
  final String? adminResponseReason; // New field for admin's response reason
  final Map<String, dynamic>? roomDetails;
  final Map<String, dynamic>? userDetails;

  BookingModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.date,
    required this.time,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.rating,
    this.feedback,
    this.adminResponseReason,
    this.roomDetails,
    this.userDetails,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc, {
    Map<String, dynamic>? roomData,
    Map<String, dynamic>? userData,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BookingModel(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      purpose: data['purpose'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      rating: data['rating']?.toDouble(),
      feedback: data['feedback'],
      adminResponseReason: data['adminResponseReason'],
      roomDetails: roomData,
      userDetails: userData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'userId': userId,
      'date': date,
      'time': time,
      'purpose': purpose,
      'status': status,
      'createdAt': createdAt,
      'rating': rating,
      'feedback': feedback,
      'adminResponseReason': adminResponseReason,
      'roomDetails': roomDetails,
      'userDetails': userDetails,
      'roomName': roomDetails?['name'] ?? 'Room $roomId',
      'building': roomDetails?['building'] ?? '-',
      'floor': roomDetails?['floor']?.toString() ?? '-',
      'capacity': roomDetails?['capacity'] ?? 0,
      'features': roomDetails?['features'] ?? [],
      'userName': userDetails?['name'] ?? 'Anonymous',
    };
  }
  
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      userId: map['userId'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      purpose: map['purpose'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      rating: map['rating']?.toDouble(),
      feedback: map['feedback'],
      adminResponseReason: map['adminResponseReason'],
      roomDetails: map['roomDetails'],
      userDetails: map['userDetails'],
    );
  }

  bool get isActive => status == 'pending' || status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected => status == 'rejected';
}