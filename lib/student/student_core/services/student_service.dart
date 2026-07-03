import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Student.dart';
import '../../../core/user/user_service.dart';
import '../../../core/enums.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  Stream<StudentModel?> watchLocalStudent(String uid) {
    return _db.collection('students').doc(uid).snapshots(source: ListenSource.cache).map((snap) {
      return snap.exists ? StudentModel.fromMap(snap.id, snap.data()!) : null;
    });
  }

  Future<void> createStudentAccount({
    required String uid,
  }) async {
    final batch = _db.batch();

    final usersRef = _db.collection('users').doc(uid);
    batch.update(usersRef, {
      'role': roles.student.name,
    });

    final studentsRef = _db.collection('students').doc(uid);
    batch.set(studentsRef, {
      'assignedDriverId': null,
    });

    await batch.commit();
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

    final rosterRef = _db.collection('rosters').doc(driverDocId);
    batch.set(
      rosterRef,
      {
        'students': {
          studentUid: {
            'displayName': displayName,
            'defaultMorning': true,
            'defaultEvening': true,
            'defaultCheckpoint': null,
          }
        }
      },
      SetOptions(merge: true),
    );

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