import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user == null) {
        return false;
      }
      
      final userData = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userData.exists) {
        return false;
      }
      
      return userData.data()?['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
    // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }
  
  // Note: Registration functionality is intentionally disabled
  // as per application requirements
  
  // Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }
}