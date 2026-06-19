import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';

class StudentDisplayNameNotifier extends AutoDisposeAsyncNotifier<String> {
  @override
  Future<String> build() async {
    final user = await ref.watch(currentUserProvider.future);
    return user?.displayName ?? '';
  }

  void updateName(String newName) {
    state = AsyncData(newName);
  }

  Future<void> saveChanges() async {
    final newName = state.valueOrNull;
    if (newName == null) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) throw Exception('User not logged in');

    final student = await ref.read(studentProvider(user.uid).future);
    final driverId = student?.assignedDriverId;
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
