import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class SharedTripService {
  SharedTripService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<TripModel>> watchDriverTrips(String driverId) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .where('disabled', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TripModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<TripModel>> watchStudentTrips(String driverId, String studentId) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .where('disabled', isEqualTo: false)
        .where('participants', arrayContains: studentId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TripModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<TripLegConfig?> watchTripDefaults(String driverId, String tripId, TripLegDirection direction) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .doc(tripId)
        .collection('config')
        .doc('${direction.name}_defaults')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return TripLegConfig.fromMap(snap.data()!, snap.id);
    });
  }

  Stream<TripLegResponse?> watchTripResponse(String driverId, String tripId, TripLegDirection direction, String dateString) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .doc(tripId)
        .collection('responses')
        .doc('${direction.name}_$dateString')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return TripLegResponse.fromMap(snap.data()!, snap.id);
    });
  }
}

final sharedTripServiceProvider = Provider<SharedTripService>((ref) {
  return SharedTripService();
});
