import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email & password
  Future<UserCredential?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role, // 'passenger' or 'rider'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Save user profile to Firestore
    await _db.collection(role == 'rider' ? 'riders' : 'users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      if (role == 'rider') 'isVerified': false,
      if (role == 'rider') 'isOnline': false,
      if (role == 'rider') 'rating': 0.0,
      if (role == 'rider') 'totalTrips': 0,
    });
    return cred;
  }

  // Login
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    final passengerDoc = await _db.collection('users').doc(uid).get();
    if (passengerDoc.exists) return 'passenger';
    final riderDoc = await _db.collection('riders').doc(uid).get();
    if (riderDoc.exists) return 'rider';
    return null;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
