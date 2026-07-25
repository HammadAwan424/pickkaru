import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user.dart';

class UserNotFoundException implements Exception {
  final String uid;
  final String code;
  final String message;

  const UserNotFoundException(
    this.uid, {
    this.code = 'user-not-found',
    this.message = 'User document does not exist in Firestore.',
  });

  @override
  String toString() => 'UserNotFoundException($code): $message (uid: $uid)';
}

class UsernameTakenException implements Exception {
  final String username;
  final String code;
  final String message;

  const UsernameTakenException(
    this.username, {
    this.code = 'username-taken',
    this.message = 'The username is already taken.',
  });

  @override
  String toString() => 'UsernameTakenException($code): $message (username: $username)';
}

class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<BaseUserModel> watchLocalUser(String uid, {String? claimRole}) {
    return _db
        .collection("users")
        .doc(uid)
        .snapshots(source: ListenSource.cache)
        .map((snap) {
          if (!snap.exists || snap.data() == null) {
            throw UserNotFoundException(uid);
          }
          return BaseUserModel.fromMap(snap.id, snap.data()!, claimRole: claimRole);
        });
  }

  Future<void> createInitialProfile(PendingUserModel user) async {
    final usernameRef = _db.collection('usernames').doc(user.username);
    final userProfileRef = _db.collection('users').doc(user.uid);

    final checkDoc = await usernameRef.get();
    if (checkDoc.exists) {
      throw UsernameTakenException(user.username);
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
        throw UsernameTakenException(user.username);
      }
      rethrow;
    }
  }
}

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});
