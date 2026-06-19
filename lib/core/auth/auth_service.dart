import 'package:firebase_auth/firebase_auth.dart';
class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();
}
