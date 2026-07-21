import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../student_core/services/student_service.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';

class StudentDisplayNameNotifier extends AutoDisposeAsyncNotifier<String> {
  @override
  Future<String> build() async {
    final user = ref.watch(requireUserProvider);
    return user.displayName;
  }

  void updateName(String newName) {
    state = AsyncData(newName);
  }

  Future<void> saveChanges() async {
    final newName = state.valueOrNull;
    if (newName == null) return;

    final user = ref.read(requireUserProvider);

    final student = ref.read(requireStudentProvider);
    final driverId = student.assignedDriverId;
    if (driverId == null) throw Exception('No driver assigned');

    await ref.read(studentServiceProvider).updateDisplayName(
          assignedDriverId: driverId,
          uid: user.uid,
          newDisplayName: newName,
        );
  }
}

final studentDisplayNameNotifierProvider =
    AsyncNotifierProvider.autoDispose<StudentDisplayNameNotifier, String>(
  () => StudentDisplayNameNotifier(),
);
