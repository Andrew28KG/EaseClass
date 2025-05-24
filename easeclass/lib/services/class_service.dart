import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'classes';
  
  Future<List<ClassModel>> getClasses() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ClassModel.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting classes: $e');
      return [];
    }
  }
  
  Future<ClassModel?> getClassById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return ClassModel.fromMap({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      print('Error getting class by id: $e');
      return null;
    }
  }
  
  Stream<List<ClassModel>> getClassesStream() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ClassModel.fromMap({
              'id': doc.id,
              ...data,
            });
          }).toList();
        });
  }
  
  Future<String> addClass(ClassModel classModel) async {
    try {
      final docRef = await _firestore.collection(_collection).add(classModel.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding class: $e');
      throw e;
    }
  }
  
  Future<void> updateClass(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (e) {
      print('Error updating class: $e');
      throw e;
    }
  }
  
  Future<void> deleteClass(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting class: $e');
      throw e;
    }
  }
}