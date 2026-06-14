import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

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
    batch.set(
      rosterRef,
      {'students.$uid.displayName': newDisplayName},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> updateStudentDefaults({
    required String uid,
    required String assignedDriverId,
    required bool defaultMorning,
    required bool defaultEvening,
    required String? defaultCheckpoint,
  }) async {
    await _db.collection('rosters').doc(assignedDriverId).update({
      'students.$uid.defaultMorning': defaultMorning,
      'students.$uid.defaultEvening': defaultEvening,
      'students.$uid.defaultCheckpoint': defaultCheckpoint,
    });
  }
}
