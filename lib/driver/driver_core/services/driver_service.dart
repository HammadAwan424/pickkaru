import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Driver.dart';
import '../../../core/enums.dart';

// driver_service.dart — Firestore driver doc concerns
class DriverService {
  final _db = FirebaseFirestore.instance;

  Stream<DriverModel?> watchLocalDriver(String uid) {
    return _db.collection('drivers').doc(uid).snapshots(source: ListenSource.cache).map((snap) {
      return snap.exists ? DriverModel.fromMap(snap.id, snap.data()!) : null;
    });
  }

  Future<void> createDriverAccount(DriverModel driver) async {
    final batch = _db.batch();

    final usersRef = _db.collection('users').doc(driver.uid);
    batch.update(usersRef, {
      'role': roles.driver.name,
    });

    final driversRef = _db.collection('drivers').doc(driver.uid);
    batch.set(driversRef, driver.toMap());

    await batch.commit();
  }
}

final driverServiceProvider = Provider((ref) => DriverService());
