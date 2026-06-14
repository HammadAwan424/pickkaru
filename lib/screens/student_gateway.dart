import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/student_provider.dart';
import '../providers/auth_provider.dart';
import 'student_shell.dart';
import 'student_driver_assignment_page.dart';

// lib/features/shell/student_gateway.dart
class StudentGateway extends ConsumerWidget {
  const StudentGateway({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final studentAsync = ref.watch(studentProvider(user.uid));
    return studentAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (student) {
        if (student == null || student.assignedDriverId == null) {
          return _UnassignedView(studentUid: user.uid);
        }
        return const StudentShell();
      },
    );
  }
}

class _UnassignedView extends StatelessWidget {
  final String studentUid;
  const _UnassignedView({required this.studentUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickkaru')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No driver assigned'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentDriverAssignmentPage(studentUid: studentUid),
                ),
              ),
              child: const Text('Assign a Driver'),
            ),
          ],
        ),
      ),
    );
  }
}