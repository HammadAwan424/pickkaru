import 'package:cloud_firestore/cloud_firestore.dart';
import '../student.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  Stream<StudentModel?> watchStudent(String uid) {
    return _db.collection('students').doc(uid).snapshots().map((snap) {
      return snap.exists ? StudentModel.fromMap(snap.id, snap.data()!) : null;
    });
  }

  Future<void> updateDisplayName({
    required String assignedDriverId,
    required String uid,
    required String newDisplayName,
  }) async {
    final batch = _db.batch();

    final usersRef = _db.collection('users').doc(uid);
    batch.update(usersRef, {'displayName': newDisplayName});

    final rosterRef = _db.collection('rosters').doc(assignedDriverId);
    batch.update(
      rosterRef,
      {'students.$uid.displayName': newDisplayName},
    );

    await batch.commit();
  }
}
