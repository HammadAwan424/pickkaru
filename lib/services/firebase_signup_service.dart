import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/enums.dart';



class FirebaseSignupService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Signs up a user using a username + secret code.
  ///
  /// This scaffold maps `username` to a synthetic email of the form
  /// `<username>@gmail.com` in order to reuse Firebase Email/Password auth.
  Future<String> signUpWithUsername({
    required String username,
    required String secret,
    required roles role,
  }) async {
    final email = '${username.toLowerCase()}@gmail.com';

    // Create auth user, if it exists, this will throw an error which we can catch and show to the user
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: secret);
    final uid = cred.user?.uid;
    if (uid == null) throw Exception('Failed to create user');

    // code proceeds to this line only if there is no user with current uid
    // Create a Firestore profile document at `users/{uid}` following the app model
    await _db.collection('users').doc(uid).set({
      'role': role == roles.student ? roles.student.name : roles.driver.name,
      'displayName': username,
      'username': username,
    });

    return uid;
  }

  Future<String?> _resolveDriverDocId(String driverId) async {
    final doc = await _db.collection('users').doc(driverId).get();
    if (doc.exists && doc.data()?['role'] == roles.driver.name) {
      return doc.id;
    }

    final query = await _db
        .collection('users')
        .where('username', isEqualTo: driverId)
        .where('role', isEqualTo: 'driver')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    return null;
  }

  Future<bool> driverExists(String driverId) async {
    return await _resolveDriverDocId(driverId) != null;
  }

  Future<void> assignDriverToStudent({
    required String studentUid,
    required String driverId,
  }) async {
    final driverDocId = await _resolveDriverDocId(driverId);
    if (driverDocId == null) {
      throw Exception('Driver does not exist');
    }

    await _db.collection('students').doc(studentUid).update({
      'assignedDriverId': driverDocId,
    });
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // since this handles both sign-in and sign-up,
  // we only create a user document if one doesn't already exist for the signed-in Google user
  Future<void> signInWithGoogle([roles? role]) async {
    if (kIsWeb) {
      throw Exception(
          'Google sign-in is not supported on web in this scaffold');
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
    final roleStr = role == null
        ? 'student'
        : (role == roles.student ? 'student' : 'driver');
    if (uid != null) {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(uid).set({
          'role': roleStr,
          'displayName': userCred.user?.displayName ?? '',
          'username': userCred.user?.email?.split('@').first ?? uid,
        });
      }
    }
  }
}
