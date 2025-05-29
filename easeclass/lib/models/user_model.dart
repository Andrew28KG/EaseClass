import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String role;
  final String? displayName;
  final String? photoUrl;
  final Timestamp createdAt;
  final Map<String, dynamic>? preferences;
  final String? nim;
  final String? department;
  final String? password;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.preferences,
    this.nim,
    this.department,
    this.password,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      preferences: data['preferences'],
      nim: data['nim'],
      department: data['department'],
      password: data['password'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'preferences': preferences,
      'nim': nim,
      'department': department,
      'password': password,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    String? displayName,
    String? photoUrl,
    Timestamp? createdAt,
    Map<String, dynamic>? preferences,
    String? nim,
    String? department,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
      nim: nim ?? this.nim,
      department: department ?? this.department,
      password: password ?? this.password,
    );
  }
} 