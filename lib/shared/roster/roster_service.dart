import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'Roster.dart';

class SharedRosterService {
  final _db = FirebaseFirestore.instance;

  Stream<Roster?> watchLocalRoster(String driverId) {
    return _db
        .collection('rosters')
        .doc(driverId)
        .snapshots(source: ListenSource.cache)
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Roster.fromMap(driverId, snap.data()!);
    });
  }
}

final sharedRosterServiceProvider = Provider((ref) => SharedRosterService());
