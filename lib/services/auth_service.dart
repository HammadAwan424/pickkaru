import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<UserModel?> get currentUserStream {
    return _auth.authStateChanges().asyncExpand((firebaseUser) async* {
      if (firebaseUser == null) {
        yield null;
        return;
      }

      try {
        final doc = await _db.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          yield UserModel.fromMap(firebaseUser.uid, doc.data() ?? {});
        } else {
          yield null;
        }
      } catch (e) {
        yield null;
      }
    });
  }

  User? get currentFirebaseUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();
}
