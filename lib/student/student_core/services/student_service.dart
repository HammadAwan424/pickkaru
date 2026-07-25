import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Student.dart';
import '../../../core/enums.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  Stream<StudentProfile?> watchLocalStudent(String uid) {
    return _db.collection('students').doc(uid).snapshots(source: ListenSource.cache).map((snap) {
      return snap.exists ? StudentProfile.fromMap(snap.data()!) : null;
    });
  }

  Future<void> createStudentAccount(StudentProfile student) async {
    final batch = _db.batch();

    final usersRef = _db.collection('users').doc(student.uid);
    batch.update(usersRef, {
      'role': roles.student.name,
    });

    final studentsRef = _db.collection('students').doc(student.uid);
    batch.set(studentsRef, student.toMap());

    await batch.commit();
  }

  Future<void> updateDisplayName({
    required String assignedDriverId,
    required String uid,
    required String newDisplayName,
  }) async {
    final usersRef = _db.collection('users').doc(uid);
    await usersRef.update({'displayName': newDisplayName});
  }

  Future<void> assignDriverToStudent({
    required String studentUid,
    required String driverId,
    required String displayName,
  }) async {
    final driverDocId = await _resolveDriverDocId(driverId);
    if (driverDocId == null) {
      throw Exception('Driver does not exist');
    }

    final batch = _db.batch();

    final studentRef = _db.collection('students').doc(studentUid);
    batch.update(studentRef, {'assignedDriverId': driverDocId});

    final driverRef = _db.collection('drivers').doc(driverDocId);
    batch.update(driverRef, {
      'assignedStudents': FieldValue.arrayUnion([studentUid]),
    });

    await batch.commit();
  }

  Future<bool> driverExists(String driverId) async {
    return await _resolveDriverDocId(driverId) != null;
  }

  Future<String?> _resolveDriverDocId(String driverId) async {
    final doc = await _db.collection('users').doc(driverId).get();
    if (doc.exists && doc.data()?['role'] == 'driver') {
      return doc.id;
    }

    final query = await _db
        .collection('users')
        .where('username', isEqualTo: driverId)
        .where('role', isEqualTo: 'driver')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    return null;
  }
}

final studentServiceProvider = Provider((ref) => StudentService());