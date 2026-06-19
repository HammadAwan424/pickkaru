import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../student/student_core/providers/student_provider.dart';
import '../enums.dart';
import '../../driver/layout/driver_shell.dart';
import '../../student/layout/student_shell.dart';
import '../../student/driver_assignment/student_driver_assignment_page.dart';
import '../home/role_selection_page.dart';

class AuthenticatedHomePage extends ConsumerStatefulWidget {
  const AuthenticatedHomePage({super.key});

  @override
  ConsumerState<AuthenticatedHomePage> createState() =>
      _AuthenticatedHomePageState();
}

class _AuthenticatedHomePageState extends ConsumerState<AuthenticatedHomePage> {
  @override
  Widget build(BuildContext context) {
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
          return const RoleSelectionPage();
        }

        if (user.role == roles.driver) {
          return const DriverShell();
        }

        // It is a student, watch their setup state dynamically
        final studentAsync = ref.watch(studentProvider(user.uid));
        
        return studentAsync.when(
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
                'Error loading student record: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          data: (student) {
            if (student == null || student.assignedDriverId == null) {
              return StudentDriverAssignmentPage(studentUid: user.uid);
            }
            return const StudentShell();
          },
        );
      },
    );
  }
}
