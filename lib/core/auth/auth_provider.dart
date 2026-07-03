import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pickkaru/core/user/user.dart';
import 'package:pickkaru/core/auth/auth_service.dart';
import 'package:pickkaru/core/user/user_service.dart';

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
      return ref.watch(userServiceProvider).watchLocalUser(firebaseUser.uid);
    },
  );
});
