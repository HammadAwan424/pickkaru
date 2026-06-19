import 'package:cloud_firestore/cloud_firestore.dart';
import 'roster.dart';

class SharedRosterService {
  final _db = FirebaseFirestore.instance;

  Stream<Roster?> watchRoster(String driverId) {
    return _db.collection('rosters').doc(driverId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Roster.fromMap(driverId, snap.data()!);
    });
  }

// Inside RosterService
  Future<void> updateStudentDefaults({
    required String driverId,
    required String studentId,
    bool? morning,
    bool? evening,
    String? checkpoint,
  }) async {
    // Only add fields to the update map if they are NOT null
    final updates = <String, dynamic>{
      if (morning != null) 'students.$studentId.defaultMorning': morning,
      if (evening != null) 'students.$studentId.defaultEvening': evening,
      if (checkpoint != null)
        'students.$studentId.defaultCheckpoint': checkpoint,
    };

    if (updates.isEmpty) return; // Nothing to do!

    await _db.collection('rosters').doc(driverId).update(updates);
  }
}
