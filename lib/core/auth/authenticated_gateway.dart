import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../enums.dart';
import '../../driver/layout/driver_gateway.dart';
import '../../student/layout/student_gateway.dart';
import '../home/role_selection_page.dart';
import '../home/username_selection_page.dart';
import '../user/user.dart';

import '../../driver/driver_core/providers/driver_provider.dart';
import '../../student/student_core/providers/student_provider.dart';

class AuthenticatedGateway extends ConsumerWidget {
  const AuthenticatedGateway({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize both domain providers so they fetch concurrently 
    // with the base user profile, completely eliminating the loading waterfall.
    // Using ref.listen keeps them alive without causing this widget to rebuild.
    ref.listen(studentProvider, (_, __) {});
    ref.listen(driverProvider, (_, __) {});

    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Center(
          child: Text(
            'Error loading profile: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const UsernameSelectionPage();
        }

        return switch (user) {
          PendingUserProfile() => const RoleSelectionPage(),
          UserModel(role: roles.driver) => const DriverGateway(),
          UserModel(role: _) => const StudentGateway(),
        };
      },
    );
  }
}

