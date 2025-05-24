import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String name;
  final String description;
  final String building;
  final int floor;
  final int capacity;
  final double rating;
  final bool isAvailable;
  final List<String> features;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  ClassModel({
    required this.id,
    required this.name,
    required this.description,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.rating,
    required this.isAvailable,
    required this.features,
    this.imageUrl,
    this.metadata,
  });

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
      metadata: data['metadata'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'rating': rating,
      'isAvailable': isAvailable,
      'features': features,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }
  
  factory ClassModel.fromMap(Map<String, dynamic> map) {
    // Handle features list
    List<String> featuresList = [];
    if (map['features'] != null) {
      if (map['features'] is List) {
        featuresList = List<String>.from(map['features']);
      }
    }
    
    return ClassModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      building: map['building'] ?? '',
      floor: map['floor'] ?? 1,
      capacity: map['capacity'] ?? 20,
      rating: (map['rating'] ?? 0.0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      features: featuresList,
      imageUrl: map['imageUrl'],
      metadata: map['metadata'],
    );
  }
}