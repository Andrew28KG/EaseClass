import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_slot.dart';

class ClassModel {
  final String id;
  final String name;
  final String description;
  final String building;
  final int floor;
  final int capacity;
  final bool isAvailable;
  final List<String> features;
  final double rating;
  final String? imageUrl;
  final List<TimeSlot>? timeSlots;
  final Map<String, dynamic>? metadata;

  ClassModel({
    required this.id,
    required this.name,
    required this.description,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.isAvailable,
    required this.features,
    this.rating = 0.0,
    this.imageUrl,
    this.timeSlots,
    this.metadata,
  });

  ClassModel copyWith({
    String? id,
    String? name,
    String? description,
    String? building,
    int? floor,
    int? capacity,
    bool? isAvailable,
    List<String>? features,
    double? rating,
    String? imageUrl,
    List<TimeSlot>? timeSlots,
    Map<String, dynamic>? metadata,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      isAvailable: isAvailable ?? this.isAvailable,
      features: features ?? this.features,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      timeSlots: timeSlots ?? this.timeSlots,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle features list
    List<String> featuresList = [];
    if (data['features'] != null) {
      featuresList = List<String>.from(data['features']);
    }
    
    return ClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      building: data['building'] ?? '',
      floor: data['floor'] ?? 1,
      capacity: data['capacity'] ?? 20,
      rating: (data['rating'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      features: featuresList,
      imageUrl: data['imageUrl'],
      timeSlots: (data['timeSlots'] as List<dynamic>?)
          ?.map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
          .toList(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'isAvailable': isAvailable,
      'features': features,
      'rating': rating,
      'imageUrl': imageUrl,
      'timeSlots': timeSlots?.map((slot) => slot.toMap()).toList(),
      'metadata': metadata,
    };
  }
  
  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      building: map['building'] ?? '',
      floor: map['floor']?.toInt() ?? 0,
      capacity: map['capacity']?.toInt() ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      features: List<String>.from(map['features'] ?? []),
      rating: map['rating']?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
      timeSlots: (map['timeSlots'] as List<dynamic>?)
          ?.map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
          .toList(),
      metadata: map['metadata'],
    );
  }
}