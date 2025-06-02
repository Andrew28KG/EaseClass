class TimeSlot {
  final String day;
  final String startTime;
  final String endTime;
  final String? courseEvent;

  TimeSlot({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.courseEvent,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'courseEvent': courseEvent,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      courseEvent: map['courseEvent'],
    );
  }
} 