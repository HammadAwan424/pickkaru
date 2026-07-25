import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_provider.dart';

class RootRouter extends ConsumerWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth Error: $e')),
      ),
      data: (authData) {
        return Scaffold(
          body: Center(
            child: Text(
              authData == null
                  ? 'Unauthenticated (Ready for new UI)'
                  : 'Authenticated User: ${authData.user.uid}',
            ),
          ),
        );
      },
    );
  }
}