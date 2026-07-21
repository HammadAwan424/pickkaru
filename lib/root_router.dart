import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/home/home_page.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/authenticated_gateway.dart';

// root_router.dart — watches raw auth state
class RootRouter extends ConsumerWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error:   (e, _) => const HomePage(),
      data: (firebaseUser) {
        if (firebaseUser == null) return const HomePage();
        return const AuthenticatedGateway(); // user is authenticated, hand off
      },
    );
  }
}