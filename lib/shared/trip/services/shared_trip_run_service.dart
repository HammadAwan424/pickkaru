import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class SharedTripRunService {
  SharedTripRunService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<TripRunDay?> watchTripRunDay(String driverId, String dateString) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('tripRuns')
        .doc(dateString)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return TripRunDay.fromMap(snap.data()!, snap.id);
    });
  }
}

final sharedTripRunServiceProvider = Provider<SharedTripRunService>((ref) {
  return SharedTripRunService();
});
