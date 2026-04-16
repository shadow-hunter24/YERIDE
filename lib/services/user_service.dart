import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    // Check passengers first
    final passengerDoc = await _db.collection('users').doc(uid).get();
    if (passengerDoc.exists) return passengerDoc.data();

    // Then riders
    final riderDoc = await _db.collection('riders').doc(uid).get();
    if (riderDoc.exists) return riderDoc.data();

    return null;
  }
}
