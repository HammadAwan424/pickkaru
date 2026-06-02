import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver.dart';

// driver_service.dart — Firestore driver doc concerns
class DriverService {
  final _db = FirebaseFirestore.instance;

  Stream<DriverModel?> watchDriver(String uid) {
    return _db.collection('drivers').doc(uid).snapshots().map((snap) {
      return snap.exists ? DriverModel.fromMap(snap.id, snap.data()!) : null;
    });
  }
}
