import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../user/user_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  Future<User> signInWithGoogle() async {
    if (kIsWeb) {
      throw Exception('Google sign-in is not supported on web in this scaffold');
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

    return user;
  }
}

final authServiceProvider = Provider((ref) => AuthService());
