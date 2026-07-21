import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/shared/date/format_date.dart';

class StudentTripService {
  StudentTripService({FirebaseFirestore? firestore}) 
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> updateStudentTripDefault({
    required String driverId,
    required String tripId,
    required TripLegDirection direction,
    required String studentId,
    required CoreStudentLegData newValue,
    required DateTime today,
  }) async {
    final docRef = _db
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .doc(tripId)
        .collection('config')
        .doc('${direction.name}_defaults');

    final todayStr = formatDate(today);
    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowStr = formatDate(tomorrow);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final rawStudents = data['students'] as Map<String, dynamic>? ?? {};
      final rawEntry = rawStudents[studentId] as Map<String, dynamic>?;
      if (rawEntry == null) return;

      final activeData = rawEntry['active'] as Map<String, dynamic>? ?? {};
      final pendingData = rawEntry['pending'] as Map<String, dynamic>?;

      Map<String, dynamic> resolvedActive = Map<String, dynamic>.from(activeData);

      // If a previous pending change has already come due, it's the new baseline.
      if (pendingData != null) {
        final effectiveFrom = pendingData['effectiveFrom'] as String?;
        if (effectiveFrom != null && effectiveFrom.compareTo(todayStr) <= 0) {
          resolvedActive = Map<String, dynamic>.from(pendingData)
            ..remove('effectiveFrom');
        }
      }

      final newPending = {
        ...newValue.toMap(),
        'effectiveFrom': tomorrowStr,
      };

      tx.update(docRef, {
        'students.$studentId.active': resolvedActive,
        'students.$studentId.pending': newPending,
      });
    });
  }

  Future<void> submitStudentResponse({
    required String driverId,
    required String tripId,
    required TripLegDirection direction,
    required String dateString,
    required String studentId,
    required CoreStudentLegData coreData,
  }) async {
    final docId = '${direction.name}_$dateString';
    final ref = _db
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .doc(tripId)
        .collection('responses')
        .doc(docId);

    final updates = <String, dynamic>{};
    coreData.toMap().forEach((k, v) {
      updates['students.$studentId.$k'] = v;
    });

    if (updates.isEmpty) return;

    await ref.set(updates, SetOptions(merge: true));
  }

  Future<void> markStudentBoarded({
    required String driverId,
    required String tripId,
    required TripLegDirection direction,
    required String dateString,
    required String studentId,
    required bool boarded,
  }) async {
    final docId = '${direction.name}_$dateString';
    final ref = _db
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .doc(tripId)
        .collection('responses')
        .doc(docId);

    await ref.set({
      'students.$studentId.boarded': boarded,
    }, SetOptions(merge: true));
  }

  Future<void> markStudentDroppedOff({
    required String driverId,
    required String tripId,
    required TripLegDirection direction,
    required String dateString,
    required String studentId,
    required bool droppedOff,
  }) async {
    final docId = '${direction.name}_$dateString';
    final ref = _db
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .doc(tripId)
        .collection('responses')
        .doc(docId);

    await ref.set({
      'students.$studentId.droppedOff': droppedOff,
    }, SetOptions(merge: true));
  }
}

final studentTripServiceProvider = Provider<StudentTripService>((ref) {
  return StudentTripService();
});
