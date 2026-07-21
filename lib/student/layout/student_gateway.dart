import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../student_core/providers/student_provider.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';
import '../trip/providers/student_trip_providers.dart';
import '../student_core/Student.dart';
import 'student_shell.dart';
import '../driver_assignment/student_driver_assignment_page.dart';

// lib/features/shell/student_gateway.dart
class StudentGateway extends ConsumerWidget {
  const StudentGateway({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The gateway waits for the student doc. We know the user is authenticated.
    final studentAsync = ref.watch(studentProvider);
    
    return studentAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: Center(child: Text('Error loading student: $e'))),
      data: (student) {
        if (student == null || student is! AssignedStudentProfile) {
          final uid = ref.read(requireAuthStateProvider).user.uid;
          return _UnassignedView(studentUid: uid);
        }
        final assigned = student;
        final uid = ref.read(requireAuthStateProvider).user.uid;
        return _ActiveTripGate(uid: uid, driverId: assigned.assignedDriverId);
      },
    );
  }
}

class _ActiveTripGate extends ConsumerWidget {
  final String uid;
  final String driverId;
  const _ActiveTripGate({required this.uid, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(studentActiveTripProvider((driverId: driverId, studentId: uid)));
    return activeAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, stack) => Scaffold(body: Center(child: Text('Error loading trips: $e'))),
      data: (activeState) {
        if (activeState == null) {
          return const Scaffold(body: Center(child: Text('No trips configured for you yet.')));
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