import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pickkaru/core/user/user.dart';
import 'package:pickkaru/core/auth/auth_service.dart';
import 'package:pickkaru/core/user/user_service.dart';

typedef AuthTokenData = ({User user, Map<String, dynamic> claims});

// Firebase Auth stream — gives you uid and claims
final authStateProvider = StreamProvider<AuthTokenData?>((ref) {
  return ref.watch(authServiceProvider).idTokenChanges.asyncMap((user) async {
    if (user == null) return null;
    final tokenResult = await user.getIdTokenResult(false);
    return (user: user, claims: tokenResult.claims ?? {});
  });
});

// combines auth uid with Firestore user doc
final currentUserProvider = StreamProvider<BaseUserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
    data: (authData) {
      if (authData == null) return Stream.value(null);
      final claimRole = authData.claims['role'] as String?;
      return ref.watch(userServiceProvider).watchLocalUser(authData.user.uid, claimRole: claimRole);
    },
  );
});

// ==========================================
// STRICT PROVIDERS (Derived from Auth Chain)
// ==========================================

// 1. Strict Firebase Auth
final requireAuthStateProvider = Provider<AuthTokenData>((ref) {
  final authData = ref.watch(authStateProvider).valueOrNull;
  if (authData == null) {
    throw StateError('requireAuthStateProvider accessed but auth data is null.');
  }
  return authData;
});

// 2. Strict Core User Document
final requireUserProvider = Provider<UserModel>((ref) {
  final userDoc = ref.watch(currentUserProvider).valueOrNull;
  if (userDoc == null) {
    throw StateError('requireUserProvider accessed but user document is null.');
  }
  if (userDoc is! UserModel) {
    throw StateError('requireUserProvider accessed but user is still a PendingUserModel.');
  }
  return userDoc;
});
