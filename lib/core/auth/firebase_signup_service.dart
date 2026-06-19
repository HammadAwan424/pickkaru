import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../enums.dart';

class FirebaseSignupService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

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

  Future<void> signInWithGoogleOnly() async {
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
  }

  Future<void> createSignupFirestoreProfile({
    required String uid,
    required String username,
    required String displayName,
    required roles role,
  }) async {
    await _createSignupFirestoreProfile(
      uid: uid,
      username: username,
      displayName: displayName,
      role: role,
    );
  }

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
        'timeZoneName': 'Asia/Karachi',
      });

      final now = DateTime.now();
      final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      for (final period in ['morning', 'evening']) {
        final pollRef = _db.collection('polls').doc('${uid}_$period');
        batch.set(pollRef, {
          'driverId': uid,
          'period': period,
          'status': 'uninitiated',
          'checkpoints': period == 'morning' ? null : <String>[],
        });

        final responsesRef =
            pollRef.collection('responses').doc(today);
        batch.set(responsesRef, {
          'responses': <String, dynamic>{},
          'approachingStudentIds': <String>[],
        });
      }

      final rosterRef = _db.collection('rosters').doc(uid);
      batch.set(rosterRef, {
        'students': <String, dynamic>{},
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

    final batch = _db.batch();

    final studentRef = _db.collection('students').doc(studentUid);
    batch.update(studentRef, {'assignedDriverId': driverDocId});

    final driverRef = _db.collection('drivers').doc(driverDocId);
    batch.update(driverRef, {
      'assignedStudents': FieldValue.arrayUnion([studentUid]),
    });

    final rosterRef = _db.collection('rosters').doc(driverDocId);
    batch.set(
      rosterRef,
      {
        'students': {
          studentUid: {
            'displayName': displayName,
            'defaultMorning': true,
            'defaultEvening': true,
            'defaultCheckpoint': null,
          }
        }
      },
      SetOptions(merge: true),
    );

    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final period in ['morning', 'evening']) {
      final responsesRef = _db
          .collection('polls')
          .doc('${driverDocId}_$period')
          .collection('responses')
          .doc(today);

      final responseData = <String, dynamic>{
        'answer': null,
        'boarded': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (period == 'evening') {
        responseData['checkpoint'] = null;
      }

      batch.set(
        responsesRef,
        {
          'responses': {studentUid: responseData},
        },
        SetOptions(merge: true),
      );
    }

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
