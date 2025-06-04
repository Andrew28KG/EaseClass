import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_slot.dart';
import 'review.dart';

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
  final int totalRatings;
  final String? imageUrl;
  final List<TimeSlot>? timeSlots;
  final Map<String, dynamic>? metadata;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final int totalReviews;
  final List<Review> reviews;

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
    this.totalRatings = 0,
    this.imageUrl,
    this.timeSlots,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.totalReviews = 0,
    this.reviews = const [],
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
    int? totalRatings,
    String? imageUrl,
    List<TimeSlot>? timeSlots,
    Map<String, dynamic>? metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? totalReviews,
    List<Review>? reviews,
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
      totalRatings: totalRatings ?? this.totalRatings,
      imageUrl: imageUrl ?? this.imageUrl,
      timeSlots: timeSlots ?? this.timeSlots,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalReviews: totalReviews ?? this.totalReviews,
      reviews: reviews ?? this.reviews,
    );
  }

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    // Safely handle null or non-map data
    if (data == null || !(data is Map<String, dynamic>)) {
        // Log the error or handle it appropriately, e.g., return a default ClassModel or throw a specific error
        print('Error: Document data is null or not a Map for document ID: ${doc.id}');
        // Return a default or empty ClassModel to prevent crash
        return ClassModel(
          id: doc.id,
          name: '', // default values
          description: '',
          building: '',
          floor: 0,
          capacity: 0,
          isAvailable: false,
          features: [],
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );
    }

    final Map<String, dynamic> mapData = data;

    // Handle features list
    List<String> featuresList = [];
    if (mapData['features'] != null) {
      // Safely cast to List and then to List<String>
      if (mapData['features'] is List) {
        featuresList = List<String>.from(mapData['features'].where((item) => item is String));
      }
    }

    // Handle timeSlots list
    List<TimeSlot>? timeSlotsList;
    if (mapData['timeSlots'] != null && mapData['timeSlots'] is List) {
      try {
        timeSlotsList = (mapData['timeSlots'] as List<dynamic>)
            .where((item) => item is Map<String, dynamic>)
            .map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error parsing timeSlots for document ID: ${doc.id}, Error: $e');
        // Handle or log the error appropriately
      }
    }

    // Handle reviews list
    List<Review> reviewsList = [];
     if (mapData['reviews'] != null && mapData['reviews'] is List) {
      try {
         reviewsList = (mapData['reviews'] as List<dynamic>)
            .where((item) => item is Map<String, dynamic>)
            .map((review) => Review.fromMap(review as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error parsing reviews for document ID: ${doc.id}, Error: $e');
        // Handle or log the error appropriately
      }
    }


    return ClassModel(
      id: doc.id,
      name: mapData['name'] ?? '',
      description: mapData['description'] ?? '',
      building: mapData['building'] ?? '',
      floor: mapData['floor']?.toInt() ?? 0,
      capacity: mapData['capacity']?.toInt() ?? 0,
      rating: (mapData['rating'] ?? 0.0).toDouble(),
      totalRatings: mapData['totalRatings'] ?? 0,
      isAvailable: mapData['isAvailable'] ?? true,
      features: featuresList,
      imageUrl: mapData['imageUrl'],
      timeSlots: timeSlotsList,
      metadata: mapData['metadata'],
      createdAt: mapData['createdAt'] ?? Timestamp.now(),
      updatedAt: mapData['updatedAt'] ?? Timestamp.now(),
      totalReviews: mapData['totalReviews'] ?? 0,
      reviews: reviewsList,
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
      'totalRatings': totalRatings,
      'imageUrl': imageUrl,
      'timeSlots': timeSlots?.map((slot) => slot.toMap()).toList(),
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'totalReviews': totalReviews,
      'reviews': reviews.map((review) => review.toMap()).toList(),
    };
  }
  
  factory ClassModel.fromMap(Map<String, dynamic> map) {
     // Handle features list
    List<String> featuresList = [];
    if (map['features'] != null) {
       if (map['features'] is List) {
        featuresList = List<String>.from(map['features'].where((item) => item is String));
      }
    }

    // Handle timeSlots list
    List<TimeSlot>? timeSlotsList;
    if (map['timeSlots'] != null && map['timeSlots'] is List) {
       try {
        timeSlotsList = (map['timeSlots'] as List<dynamic>)
            .where((item) => item is Map<String, dynamic>)
            .map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error parsing timeSlots from map: $e');
        // Handle or log the error appropriately
      }
    }

     // Handle reviews list
    List<Review> reviewsList = [];
     if (map['reviews'] != null && map['reviews'] is List) {
      try {
         reviewsList = (map['reviews'] as List<dynamic>)
            .where((item) => item is Map<String, dynamic>)
            .map((review) => Review.fromMap(review as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error parsing reviews from map: $e');
        // Handle or log the error appropriately
      }
    }

    return ClassModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      building: map['building'] ?? '',
      floor: map['floor']?.toInt() ?? 0,
      capacity: map['capacity']?.toInt() ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      features: featuresList,
      rating: map['rating']?.toDouble() ?? 0.0,
      totalRatings: map['totalRatings'] ?? 0,
      imageUrl: map['imageUrl'],
      timeSlots: timeSlotsList,
      metadata: map['metadata'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
      totalReviews: map['totalReviews'] ?? 0,
      reviews: reviewsList,
    );
  }
}