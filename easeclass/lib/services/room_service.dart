import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rooms';
  
  Stream<List<RoomModel>> getRooms() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
        });
  }
  
  Future<List<RoomModel>> getAvailableRooms() async {
    final snapshot = await _firestore.collection(_collection).where('isAvailable', isEqualTo: true).get();
    return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
  }
  
  Future<RoomModel?> getRoomById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return RoomModel.fromFirestore(doc);
  }
  
  Future<void> updateRoom(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }
  
  Future<String> addRoom(RoomModel room) async {
    // Convert room to map and remove the id field
    final roomData = room.toMap();
    roomData.remove('id');
    
    final docRef = await _firestore.collection(_collection).add(roomData);
    return docRef.id;
  }
  
  Future<void> deleteRoom(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
  
  Future<List<RoomModel>> searchRooms({
    String? building,
    int? minCapacity,
    List<String>? features,
    DateTime? date,
  }) async {
    Query query = _firestore.collection(_collection).where('isAvailable', isEqualTo: true);
    
    if (building != null) {
      query = query.where('building', isEqualTo: building);
    }
    
    if (minCapacity != null) {
      query = query.where('capacity', isGreaterThanOrEqualTo: minCapacity);
    }
    
    final snapshot = await query.get();
    List<RoomModel> rooms = snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    
    // Filter by features if specified
    if (features != null && features.isNotEmpty) {
      rooms = rooms.where((room) {
        return features.every((feature) => room.features.contains(feature));
      }).toList();
    }
    
    return rooms;
  }
}