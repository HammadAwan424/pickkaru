import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverTripService {
  DriverTripService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> updateTripRunState({
    required String driverId,
    required String dateString,
    required String tripId,
    required DateTime? startedAt,
    required DateTime? completedAt,
  }) async {
    final ref = _db
        .collection('drivers')
        .doc(driverId)
        .collection('tripRuns')
        .doc(dateString);

    final updates = <String, dynamic>{
      'trips.$tripId.startedBy': driverId,
    };
    if (startedAt != null) updates['trips.$tripId.startedAt'] = startedAt.toIso8601String();
    if (completedAt != null) updates['trips.$tripId.completedAt'] = completedAt.toIso8601String();

    await ref.set(updates, SetOptions(merge: true));
  }
}

final driverTripServiceProvider = Provider<DriverTripService>((ref) {
  return DriverTripService();
});
