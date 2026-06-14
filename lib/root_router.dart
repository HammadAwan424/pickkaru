import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/screens/home_page.dart';
import 'providers/auth_provider.dart';
import 'screens/authenticated_home_page.dart';

// root_router.dart — watches raw auth state
class RootRouter extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error:   (e, _) => const HomePage(),
      data: (firebaseUser) {
        if (firebaseUser == null) return const HomePage();
        return const AuthenticatedHomePage(); // user is authenticated, hand off
      },
    );
  }
}