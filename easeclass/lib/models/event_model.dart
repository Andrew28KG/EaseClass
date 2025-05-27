import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String classId;
  final Timestamp startDate;
  final Timestamp endDate;
  final String organizerId;
  final int maxParticipants;
  final int currentParticipants;
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final Timestamp createdAt;
  final Timestamp updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.classId,
    required this.startDate,
    required this.endDate,
    required this.organizerId,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      classId: data['classId'] ?? '',
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      organizerId: data['organizerId'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      status: data['status'] ?? 'upcoming',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'classId': classId,
      'startDate': startDate,
      'endDate': endDate,
      'organizerId': organizerId,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      classId: map['classId'] ?? '',
      startDate: map['startDate'] ?? Timestamp.now(),
      endDate: map['endDate'] ?? Timestamp.now(),
      organizerId: map['organizerId'] ?? '',
      maxParticipants: map['maxParticipants'] ?? 0,
      currentParticipants: map['currentParticipants'] ?? 0,
      status: map['status'] ?? 'upcoming',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  bool get isUpcoming => status == 'upcoming';
  bool get isOngoing => status == 'ongoing';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get hasAvailableSpots => currentParticipants < maxParticipants;
} 