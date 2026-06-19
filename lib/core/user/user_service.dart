import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<UserModel?> watchUser(String uid) {
    return _db.collection("users").doc(uid)
      .snapshots()
      .map((snap) => snap.exists ? UserModel.fromMap(snap.id, snap.data()!) : null);
  }
}