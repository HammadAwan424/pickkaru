import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class SharedCheckpointService {
  SharedCheckpointService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<CheckpointSet?> watchCheckpointSet(String setId) {
    return _db.collection('checkpoints').doc(setId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CheckpointSet.fromMap(snap.data()!, snap.id);
    });
  }
}

final sharedCheckpointServiceProvider = Provider<SharedCheckpointService>((ref) {
  return SharedCheckpointService();
});
