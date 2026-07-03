import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Driver.dart';
import '../../../core/user/user_service.dart';
import '../../../core/enums.dart';

// driver_service.dart — Firestore driver doc concerns
class DriverService {
  final _db = FirebaseFirestore.instance;

  Stream<DriverModel?> watchLocalDriver(String uid) {
    return _db.collection('drivers').doc(uid).snapshots(source: ListenSource.cache).map((snap) {
      return snap.exists ? DriverModel.fromMap(snap.id, snap.data()!) : null;
    });
  }

  Future<void> createDriverAccount({
    required String uid,
  }) async {
    final batch = _db.batch();

    final usersRef = _db.collection('users').doc(uid);
    batch.update(usersRef, {
      'role': roles.driver.name,
    });

    final driversRef = _db.collection('drivers').doc(uid);
    batch.set(driversRef, {
      'assignedStudents': <String>[],
      'refreshTime': '19:00',
      'timeZoneName': 'Asia/Karachi',
    });

    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final period in ['morning', 'evening']) {
      final pollRef = _db.collection('polls').doc('${uid}_$period');
      batch.set(pollRef, {
        'driverId': uid,
        'period': period,
        'status': 'uninitiated',
        'checkpoints': period == 'morning' ? null : <String>[],
      });

      final responsesRef = pollRef.collection('responses').doc(today);
      batch.set(responsesRef, {
        'responses': <String, dynamic>{},
        'approachingStudentIds': <String>[],
      });
    }

    final rosterRef = _db.collection('rosters').doc(uid);
    batch.set(rosterRef, {
      'students': <String, dynamic>{},
    });

    await batch.commit();
  }
}


final driverServiceProvider = Provider((ref) => DriverService());
