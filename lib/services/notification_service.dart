import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Save token for the currently logged-in user (if any)
    await _saveTokenForCurrentUser();

    // Refresh token whenever it rotates
    _messaging.onTokenRefresh.listen((newToken) async {
      await _persistToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
    });
  }

  Future<void> _saveTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token != null) await _persistToken(token);
  }

  /// Writes the FCM token into both possible collections (users + riders)
  /// depending on which document exists for this uid.
  Future<void> _persistToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Try passengers collection first
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      await _db.collection('users').doc(uid).update({'fcmToken': token});
      return;
    }

    // Fall back to riders collection
    final riderDoc = await _db.collection('riders').doc(uid).get();
    if (riderDoc.exists) {
      await _db.collection('riders').doc(uid).update({'fcmToken': token});
    }
  }

  /// Call this right after a successful login/register so the token
  /// is saved even if initialize() ran before the user was authenticated.
  Future<void> saveTokenAfterLogin() async {
    await _saveTokenForCurrentUser();
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
