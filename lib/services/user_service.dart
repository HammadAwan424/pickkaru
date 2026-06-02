import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

// user_service.dart — Firestore user doc concerns
class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<UserModel?> watchUser(String uid) {
    return _db.collection("users").doc(uid)
      .snapshots()
      .map((snap) => snap.exists ? UserModel.fromMap(snap.id, snap.data()!) : null);
  }
}