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
  final Timestamp? updatedAt;
  final double? rating;
  final String? feedback;
  final String? adminResponseReason; // New field for admin's response reason
  final Map<String, dynamic> roomDetails;
  final String? extraItemsNotes; // Changed from extraItems (Map) to a single string
  final int duration;
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
    this.updatedAt,
    this.rating,
    this.feedback,
    this.adminResponseReason,
    required this.roomDetails,
    this.extraItemsNotes, // Updated constructor parameter
    this.duration = 1,
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
      updatedAt: data['updatedAt'],
      rating: data['rating']?.toDouble(),
      feedback: data['feedback'],
      adminResponseReason: data['adminResponseReason'],
      roomDetails: Map<String, dynamic>.from(data['roomDetails'] ?? {}),
      extraItemsNotes: data['extraItemsNotes'], // Updated from Firestore
      duration: data['duration'] ?? 1,
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
      'updatedAt': updatedAt,
      'rating': rating,
      'feedback': feedback,
      'adminResponseReason': adminResponseReason,
      'roomDetails': roomDetails,
      'extraItemsNotes': extraItemsNotes, // Updated toMap
      'duration': duration,
      'roomName': roomDetails['name'] ?? 'Room $roomId',
      'building': roomDetails['building'] ?? '-',
      'floor': roomDetails['floor']?.toString() ?? '-',
      'capacity': roomDetails['capacity'] ?? 0,
      'features': roomDetails['features'] ?? [],
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
      updatedAt: map['updatedAt'],
      rating: map['rating']?.toDouble(),
      feedback: map['feedback'],
      adminResponseReason: map['adminResponseReason'],
      roomDetails: Map<String, dynamic>.from(map['roomDetails'] ?? {}),
      extraItemsNotes: map['extraItemsNotes'], // Updated from Map
      duration: map['duration'] ?? 1,
      userDetails: map['userDetails'],
    );
  }

  bool get isActive => status == 'pending' || status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected => status == 'rejected';

   // Helper to calculate end time
  String get endTime {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].split(' ')[0]);
      final period = parts[1].split(' ')[1];

      int endHour = hour + duration;
      String endPeriod = period;

      if (period == 'AM' && endHour >= 12) {
        endPeriod = 'PM';
        if (endHour > 12) endHour -= 12;
      } else if (period == 'PM' && endHour >= 12 && hour != 12) {
         // Logic for PM times crossing midnight might be needed depending on requirements
         // For simplicity, assuming bookings don't cross midnight for now
          if (endHour > 12) endHour -= 12; // Convert back to 12 hour if needed
      } else if (period == 'AM' && endHour == 12) {
        endPeriod = 'PM';
      } else if (period == 'PM' && endHour >= 12 && hour == 12) {
         // Handle 12 PM + duration
          if(endHour > 12) endHour -=12;
      }

      return '${endHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $endPeriod';
    } catch (e) {
      print('Error calculating end time: $e');
      return 'N/A';
    }
  }
}