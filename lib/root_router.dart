import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/screens/home_page.dart';
import 'screens/sign_in_page.dart';
import 'providers/auth_provider.dart';
import 'screens/authenticated_home_page.dart';

// root_router.dart — watches raw auth state
class RootRouter extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const CircularProgressIndicator(),
      error:   (e, _) => const SignInPage(),
      data: (firebaseUser) {
        if (firebaseUser == null) return const HomePage();
        return const AuthenticatedHomePage(); // user is authenticated, hand off
      },
    );
  }
}