import 'package:cloud_firestore/cloud_firestore.dart';

// Assuming Review model is defined elsewhere
import 'review.dart';

class TimeSlot {
  final String? id; // Optional for TimeSlot embedded in ClassModel
  final String day;
  final String startTime;
  final String endTime;
  final String? title; // Add title field

  TimeSlot({
    this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.title, // Include in constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'title': title, // Include title in map
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      id: map['id'],
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      title: map['title'], // Map title field
    );
  }

  // Optional: override toString for easier display
  @override
  String toString() {
    return '$day: $startTime - $endTime' + (title != null && title!.isNotEmpty ? ' ($title)' : '');
  }
} 