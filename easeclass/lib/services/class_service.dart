import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/class_model.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'classes';
  
  // Get all classes
  Stream<List<ClassModel>> getClasses() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
    });
  }
  
  // Add a new class
  Future<void> addClass(ClassModel classModel) {
    return _firestore.collection(_collection).add(classModel.toMap());
  }
  
  // Update an existing class
  Future<void> updateClass(String id, Map<String, dynamic> data) {
    return _firestore.collection(_collection).doc(id).update(data);
  }
  
  // Delete a class
  Future<void> deleteClass(String id) {
    return _firestore.collection(_collection).doc(id).delete();
  }
  
  // Get a single class by ID (optional, but often useful)
  Future<ClassModel?> getClassById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ClassModel.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting class by ID: $e');
      return null;
    }
  }
  
  Future<String?> uploadClassImage(File imageFile, String classId) async {
    try {
      final storage = FirebaseStorage.instance;
      final storageRef = storage.ref().child('classes/$classId/main_image');
      
      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading class image: $e');
      // Return a placeholder URL for testing in case of failure
      return 'https://via.placeholder.com/300x200?text=Class+$classId';
    }
  }
  
  Future<void> deleteClassImage(String classId) async {
    try {
      final storage = FirebaseStorage.instance;
      await storage.ref().child('classes/$classId/main_image').delete();
    } catch (e) {
      print('Error deleting class image: $e');
    }
  }
}