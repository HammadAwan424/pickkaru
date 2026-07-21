import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<UserProfile?> watchLocalUser(String uid) {
    return _db.collection("users").doc(uid)
      .snapshots(source: ListenSource.cache)
      .map((snap) => snap.exists ? UserProfile.fromMap(snap.id, snap.data()!) : null);
  }

  Future<void> createInitialProfile(PendingUserProfile user) async {
    final usernameRef = _db.collection('usernames').doc(user.username);
    final userProfileRef = _db.collection('users').doc(user.uid);

    final checkDoc = await usernameRef.get();
    if (checkDoc.exists) {
      throw Exception('username-taken');
    }

    final batch = _db.batch();
    
    batch.set(usernameRef, {
      'uid': user.uid,
    });

    batch.set(userProfileRef, user.toMap());

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
