import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // Create a new trip request
  Future<String> createTrip({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    required double distanceKm,
    required double fare,
    String? assignedRiderId,
  }) async {
    final doc = await _db.collection('trips').add({
      'passengerId': _uid,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinationAddress': destinationAddress,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'distanceKm': distanceKm,
      'fare': fare,
      'status': 'pending',
      'assignedRiderId': assignedRiderId,
      'riderId': null,
      'riderName': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Listen to a trip's status changes
  Stream<DocumentSnapshot> listenToTrip(String tripId) {
    return _db.collection('trips').doc(tripId).snapshots();
  }

  // Rider accepts a trip
  Future<void> acceptTrip(String tripId, String riderName) async {
    await _db.collection('trips').doc(tripId).update({
      'riderId': _uid,
      'riderName': riderName,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update trip status
  Future<void> updateTripStatus(String tripId, String status) async {
    await _db.collection('trips').doc(tripId).update({
      'status': status,
      '${status}At': FieldValue.serverTimestamp(),
    });
  }

  // Update rider live location during trip
  Future<void> updateRiderLocation(
      String tripId, double lat, double lng) async {
    await _db.collection('trips').doc(tripId).update({
      'riderLat': lat,
      'riderLng': lng,
    });
  }

  // Complete trip and save to history
  Future<void> completeTrip(String tripId, double fare) async {
    await _db.collection('trips').doc(tripId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
    // Update rider earnings
    await _db.collection('riders').doc(_uid).update({
      'totalEarnings': FieldValue.increment(fare),
      'totalTrips': FieldValue.increment(1),
    });
  }

  // Get passenger trip history
  Stream<QuerySnapshot> getPassengerTrips() {
    return _db
        .collection('trips')
        .where('passengerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get rider trip history
  Stream<QuerySnapshot> getRiderTrips() {
    return _db
        .collection('trips')
        .where('riderId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get pending trips assigned to this rider
  Stream<QuerySnapshot> getPendingTrips() {
    return _db
        .collection('trips')
        .where('status', isEqualTo: 'pending')
        .where('assignedRiderId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Submit rating
  Future<void> submitRating({
    required String tripId,
    required String ratedUserId,
    required int rating,
    required String comment,
    required String raterRole, // 'passenger' or 'rider'
  }) async {
    await _db.collection('ratings').add({
      'tripId': tripId,
      'ratedUserId': ratedUserId,
      'raterId': _uid,
      'rating': rating,
      'comment': comment,
      'raterRole': raterRole,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Update average rating
    final ratingsSnap = await _db
        .collection('ratings')
        .where('ratedUserId', isEqualTo: ratedUserId)
        .get();
    final ratings = ratingsSnap.docs
        .map((d) => (d['rating'] as num).toDouble())
        .toList();
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    final collection = raterRole == 'passenger' ? 'riders' : 'users';
    await _db.collection(collection).doc(ratedUserId).update({
      'rating': double.parse(avg.toStringAsFixed(1)),
    });
  }
}
