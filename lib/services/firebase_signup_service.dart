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
    // Create the required Firestore documents for this signup using a batched write.
    await _createSignupFirestoreProfile(
      uid: uid,
      username: username,
      displayName: username,
      role: role,
    );

    return uid;
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
    final user = userCred.user;

    if (user == null) {
      throw Exception('Authentication succeeded but no user was returned.');
    }

    final isNewUser = (await _db.collection("users").doc(user.uid).get()).exists == false;
    if (isNewUser) {
      // we aren't expecting no role for signup call
      if (role == null) {
        throw StateError('New users must provide a role');
      }

      await _createSignupFirestoreProfile(
        uid: user.uid,
        username: user.email?.split('@').first ?? user.uid,
        displayName: user.displayName ?? '',
        role: role,
      );
    }
  }

  // Centralized Firestore writes for signup flows (username & Google).
  // Writes are batched and follow the structure described in docs/auth.md.
  Future<void> _createSignupFirestoreProfile({
    required String uid,
    required String username,
    required String displayName,
    required roles role,
  }) async {
    final batch = _db.batch();

    final usersRef = _db.collection('users').doc(uid);
    batch.set(usersRef, {
      'role': role == roles.student ? roles.student.name : roles.driver.name,
      'displayName': displayName,
      'username': username,
    });

    if (role == roles.driver) {
      final driversRef = _db.collection('drivers').doc(uid);
      batch.set(driversRef, {
        'assignedStudents': <String>[],
        'refreshTime': '19:00',
      });

      final morningRef = driversRef.collection('polls').doc('morning');
      batch.set(morningRef, {
        'period': 'morning',
        'checkpoints': null,
        'responses': <String, dynamic>{},
      });

      final eveningRef = driversRef.collection('polls').doc('evening');
      batch.set(eveningRef, {
        'period': 'evening',
        'checkpoints': <String>[],
        'responses': <String, dynamic>{},
      });
    } else {
      final studentsRef = _db.collection('students').doc(uid);
      batch.set(studentsRef, {
        'assignedDriverId': null,
      });
    }

    await batch.commit();
  }



  Future<void> assignDriverToStudent({
    required String studentUid,
    required String driverId,
    required String displayName,
  }) async {
    final driverDocId = await _resolveDriverDocId(driverId);
    if (driverDocId == null) {
      throw Exception('Driver does not exist');
    }

    // Perform a batched write per docs/auth.md:
    //  - set students/{studentUid}.assignedDriverId
    //  - arrayUnion student on drivers/{driverDocId}.assignedStudents
    //  - add responses entries under drivers/{driverDocId}/polls/morning and /evening
    final batch = _db.batch();

    final studentRef = _db.collection('students').doc(studentUid);
    batch.update(studentRef, {'assignedDriverId': driverDocId});

    final driverRef = _db.collection('drivers').doc(driverDocId);
    batch.update(driverRef, {
      'assignedStudents': FieldValue.arrayUnion([studentUid]),
      'publicStudentRoster.$studentUid': {
        'displayName': displayName,
        'pickupAreaPublic': null,
      }
    });

    final morningRef = driverRef.collection('polls').doc('morning');
    batch.set(
      morningRef,
      {
        'responses': {
          studentUid: {
            'answer': null,
            'boarded': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }
      },
      SetOptions(merge: true),
    );

    final eveningRef = driverRef.collection('polls').doc('evening');
    batch.set(
      eveningRef,
      {
        'responses': {
          studentUid: {
            'answer': null,
            'checkpoint': null,
            'boarded': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<bool> driverExists(String driverId) async {
    return await _resolveDriverDocId(driverId) != null;
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
}
