import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/roster/roster_service.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';

class RosterDefaultsNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> _updateField({
    bool? morning,
    bool? evening,
    String? checkpoint,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not logged in');

      final student = await ref.read(studentProvider(user.uid).future);
      final driverId = student?.assignedDriverId;
      if (driverId == null) throw Exception('No driver assigned');

      await ref.read(studentRosterServiceProvider).updateStudentDefaults(
            driverId: driverId,
            studentId: user.uid,
            morning: morning,
            evening: evening,
            checkpoint: checkpoint,
          );
    });
  }

  Future<void> setMorning(bool value) => _updateField(morning: value);

  Future<void> setEvening(bool value) => _updateField(evening: value);

  Future<void> setCheckpoint(String value) => _updateField(checkpoint: value);
}

final rosterNotifierProvider =
    AsyncNotifierProvider.autoDispose<RosterDefaultsNotifier, void>(
  () => RosterDefaultsNotifier(),
);
