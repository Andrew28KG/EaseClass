import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String building;
  final int floor;
  final int capacity;
  final double rating;
  final bool isAvailable;
  final List<String> features;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  RoomModel({
    required this.id,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.rating,
    required this.isAvailable,
    required this.features,
    this.imageUrl,
    this.metadata,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle features list
    List<String> featuresList = [];
    if (data['features'] != null) {
      featuresList = List<String>.from(data['features']);
    }
    
    return RoomModel(
      id: doc.id,
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
} 