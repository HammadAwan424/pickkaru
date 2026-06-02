import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final userServiceProvider = Provider((ref) => UserService());

// Firebase Auth stream — gives you uid only
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// combines auth uid with Firestore user doc
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return ref.watch(userServiceProvider).watchUser(firebaseUser.uid);
    },
  );
});
