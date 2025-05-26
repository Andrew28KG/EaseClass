import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Get current user
  User? get currentUser => _auth.currentUser;  // List of admin emails
  final List<String> _adminEmails = [
    'admin@gmail.com',
    'admin@easeclass.com',
    'admin@example.com'
    // Add more admin emails as needed
  ];
  
  // List of test user emails
  final List<String> _testUserEmails = [
    'test@gmail.com',
    'user@test.com'
    // Add more test user emails as needed
  ];
  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user == null) {
        return false;
      }
      
      // First check if the email is in the admin list
      if (_adminEmails.contains(user.email)) {
        // Update the user document to set isAdmin to true
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': 'admin',
          'isAdmin': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }
      
      // If not in admin list, check the Firestore document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      // Check if user document exists and has isAdmin field set to true
      if (userDoc.exists && (userDoc.data()?['isAdmin'] == true || userDoc.data()?['role'] == 'admin')) {
        return true;
      }
      
      // If not admin, ensure the user document has the correct role
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': 'user',
        'isAdmin': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return false;
      
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  // Determine user role based on email
  String getUserRoleByEmail(String email) {
    if (_adminEmails.contains(email)) {
      return 'admin';
    } else if (_testUserEmails.contains(email)) {
      return 'user';
    } else {
      return 'user'; // Default to user role
    }
  }
  
  // Check if email is admin
  bool isAdminEmail(String email) {
    return _adminEmails.contains(email);
  }
  
  // Check if email is test user
  bool isTestUserEmail(String email) {
    return _testUserEmails.contains(email);
  }  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    
    // Set user role based on email after successful sign-in
    if (userCredential.user != null) {
      final role = getUserRoleByEmail(email);
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'isAdmin': role == 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    
    return userCredential;
  }
  
  // Note: Registration functionality is intentionally disabled
  // as per application requirements
  
  // Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }
  
  // Add this method to the AuthService class  /// Sign in with email and password and check if user is admin
  Future<bool> signInWithEmailAndPasswordAndCheckAdmin(
    String email,
    String password,
  ) async {
    try {
      // Sign in with the provided credentials
      final userCredential = await signInWithEmailAndPassword(email, password);
      
      // Check if the user is an admin based on email
      if (userCredential.user != null) {
        return isAdminEmail(email);
      }
      
      return false;
    } catch (e) {
      rethrow;
    }
  }
}