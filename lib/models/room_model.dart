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
  final String name;
  final String description;
  final List<String> images;
  final int totalRatings;

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
    required this.name,
    required this.description,
    required this.images,
    required this.totalRatings,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle features list
    List<String> featuresList = [];
    if (data['features'] != null) {
      featuresList = List<String>.from(data['features']);
    }
      // Ensure floor is always an integer
    int floor;
    if (data['floor'] is int) {
      floor = data['floor'] ?? 1;
    } else {
      floor = int.tryParse(data['floor']?.toString() ?? '1') ?? 1;
    }
    
    // Handle images list
    List<String> imagesList = [];
    if (data['images'] != null) {
      imagesList = List<String>.from(data['images']);
    }
    
    return RoomModel(
      id: doc.id,
      building: data['building'] ?? '',
      floor: floor,
      capacity: data['capacity'] ?? 20,
      rating: (data['rating'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      features: featuresList,
      imageUrl: data['imageUrl'],
      metadata: data['metadata'],
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      images: imagesList,
      totalRatings: data['totalRatings'] ?? 0,
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
      'name': name,
      'description': description,
      'images': images,
      'totalRatings': totalRatings,
    };
  }
  
  factory RoomModel.fromMap(Map<String, dynamic> map) {
    // Handle features list
    List<String> featuresList = [];
    if (map['features'] != null) {
      if (map['features'] is List) {
        featuresList = List<String>.from(map['features']);
      }
    }
      // Ensure floor is always an integer
    int floor;
    if (map['floor'] is int) {
      floor = map['floor'] ?? 1;
    } else {
      floor = int.tryParse(map['floor']?.toString() ?? '1') ?? 1;
    }
    
    // Handle images list
    List<String> imagesList = [];
    if (map['images'] != null) {
      if (map['images'] is List) {
        imagesList = List<String>.from(map['images']);
      }
    }
    
    return RoomModel(
      id: map['id'] ?? '',
      building: map['building'] ?? '',
      floor: floor,
      capacity: map['capacity'] ?? 20,
      rating: (map['rating'] ?? 0.0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      features: featuresList,
      imageUrl: map['imageUrl'],
      metadata: map['metadata'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      images: imagesList,
      totalRatings: map['totalRatings'] ?? 0,
    );
  }
}