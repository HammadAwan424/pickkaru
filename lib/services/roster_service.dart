import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/roster.dart';

class RosterService {
  final _db = FirebaseFirestore.instance;

  Stream<Roster?> watchRoster(String driverId) {
    return _db.collection('rosters').doc(driverId).snapshots().map((snap) {
      return snap.exists ? Roster.fromMap(snap.id, snap.data()!) : null;
    });
  }

  Future<void> updateRosterEntry({
    required String driverId,
    required String studentUid,
    required String displayName,
  }) async {
    await _db.collection('rosters').doc(driverId).set({
      'students.$studentUid.displayName': displayName,
    }, SetOptions(merge: true));
  }
}
