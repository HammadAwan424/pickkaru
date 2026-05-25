import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseSignupService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Signs up a user using a username + secret code.
  ///
  /// This scaffold maps `username` to a synthetic email of the form
  /// `<username>@pickkaru.app` in order to reuse Firebase Email/Password auth.
  Future<void> signUpWithUsername({
    required String username,
    required String secret,
    required String role,
    String? assignedDriverId,
  }) async {
    final email = '${username.toLowerCase()}@pickkaru.app';

    // Create auth user
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: secret);
    final uid = cred.user?.uid;
    if (uid == null) throw Exception('Failed to create user');

    // Create a Firestore profile document at `users/{uid}` following the app model
    await _db.collection('users').doc(uid).set({
      'role': role,
      'displayName': username,
      'username': username,
      'assignedDriverId': assignedDriverId,
    });
  }

  /// Sign in using Google. For web, uses `signInWithPopup`; for mobile, uses `google_sign_in`.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      final userCred = await _auth.signInWithPopup(provider);
      final uid = userCred.user?.uid;
      if (uid != null) {
        final doc = await _db.collection('users').doc(uid).get();
        if (!doc.exists) {
          await _db.collection('users').doc(uid).set({
            'role': 'student',
            'displayName': userCred.user?.displayName ?? '',
            'username': userCred.user?.email?.split('@').first ?? uid,
            'assignedDriverId': null,
          });
        }
      }
      return;
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign-in aborted');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    final uid = userCred.user?.uid;
    if (uid != null) {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(uid).set({
          'role': 'student',
          'displayName': userCred.user?.displayName ?? '',
          'username': userCred.user?.email?.split('@').first ?? uid,
          'assignedDriverId': null,
        });
      }
    }
  }
}
