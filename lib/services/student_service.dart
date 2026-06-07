import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

// student_service.dart — Firestore student doc concerns
class StudentService {
  final _db = FirebaseFirestore.instance;

  Stream<StudentModel?> watchStudent(String uid) {
    return _db.collection('students').doc(uid).snapshots().map((snap) {
      return snap.exists ? StudentModel.fromMap(snap.id, snap.data()!) : null;
    });
  }

  /// Update the student's displayName in `users/{uid}` and mirror the change
  /// into the assigned driver's `publicStudentRoster.{uid}` if a driver is assigned.
  Future<void> updateDisplayName({
    required String assignedDriverId, 
    required String uid, 
    required String newDisplayName
  }) async {

    final batch = _db.batch();

    final usersRef = _db.collection('users').doc(uid);
    batch.update(usersRef, {'displayName': newDisplayName});

    final driverRef = _db.collection('drivers').doc(assignedDriverId);
    batch.update(driverRef, {
      'publicStudentRoster.$uid.displayName': newDisplayName,
    });

    await batch.commit();
  }
  
  Future<void> updateStudentDefaults({
    required String uid,
    required bool defaultMorning,
    required bool defaultEvening,
    required String? defaultCheckpoint,
  }) async {
    await _db.collection('students').doc(uid).set({
      'defaultMorning': defaultMorning,
      'defaultEvening': defaultEvening,
      'defaultCheckpoint': defaultCheckpoint,
    }, SetOptions(merge: true));
  } 
}
