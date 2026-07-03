import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<UserModel?> watchLocalUser(String uid) {
    return _db.collection("users").doc(uid)
      .snapshots(source: ListenSource.cache)
      .map((snap) => snap.exists ? UserModel.fromMap(snap.id, snap.data()!) : null);
  }

  Future<void> createInitialProfile({
    required String uid,
    required String username,
    required String displayName,
  }) async {
    final usernameRef = _db.collection('usernames').doc(username);
    final userProfileRef = _db.collection('users').doc(uid);

    final checkDoc = await usernameRef.get();
    if (checkDoc.exists) {
      throw Exception('username-taken');
    }

    final batch = _db.batch();
    
    batch.set(usernameRef, {
      'uid': uid,
    });

    batch.set(userProfileRef, {
      'displayName': displayName,
      'username': username,
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('username-taken');
      }
      rethrow;
    }
  }
}

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});
