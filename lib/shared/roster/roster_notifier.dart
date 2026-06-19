import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/shared/roster/roster.dart';
import 'package:pickkaru/shared/roster/roster_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';

class RosterNotifier extends AutoDisposeAsyncNotifier<RosterEntry> {
  @override
  Future<RosterEntry> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) throw Exception('User not logged in');

    final student = await ref.watch(studentProvider(user.uid).future);
    final driverId = student?.assignedDriverId;
    if (driverId == null) throw Exception('No driver assigned');

    final roster = await ref.watch(rosterProvider(driverId).future);
    return roster?.students[user.uid] ??
        const RosterEntry(
          displayName: '',
          defaultMorning: false,
          defaultEvening: false,
        );
  }

  /// Ceremony helper: optimistic update → resolve IDs → sync → handle errors.
  /// Each caller provides what to change (mutate) and how to sync (sync).
  Future<void> _optimisticUpdate({
    required RosterEntry Function(RosterEntry previous) mutate,
    required Future<void> Function(String driverId, String studentId) sync,
  }) async {
    final previous = state.valueOrNull;
    if (previous == null) return;

    final updated = mutate(previous);
    if (identical(updated, previous)) return; // no-op

    state = AsyncData(updated);

    state = await AsyncValue.guard(() async {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not logged in');

      final student = await ref.read(studentProvider(user.uid).future);
      final driverId = student?.assignedDriverId;
      if (driverId == null) throw Exception('No driver assigned');

      await sync(driverId, user.uid);
      return state.valueOrNull!;
    });
  }

  Future<void> setMorning(bool value) => _optimisticUpdate(
        mutate: (prev) => prev.defaultMorning == value
            ? prev
            : prev.copyWith(defaultMorning: value),
        sync: (driverId, studentId) =>
            ref.read(rosterServiceProvider).updateStudentDefaults(
                  driverId: driverId,
                  studentId: studentId,
                  morning: value,
                ),
      );

  Future<void> setEvening(bool value) => _optimisticUpdate(
        mutate: (prev) => prev.defaultEvening == value
            ? prev
            : prev.copyWith(defaultEvening: value),
        sync: (driverId, studentId) =>
            ref.read(rosterServiceProvider).updateStudentDefaults(
                  driverId: driverId,
                  studentId: studentId,
                  evening: value,
                ),
      );

  Future<void> setCheckpoint(String value) => _optimisticUpdate(
        mutate: (prev) => prev.defaultCheckpoint == value
            ? prev
            : prev.copyWith(defaultCheckpoint: value),
        sync: (driverId, studentId) =>
            ref.read(rosterServiceProvider).updateStudentDefaults(
                  driverId: driverId,
                  studentId: studentId,
                  checkpoint: value,
                ),
      );
}

final rosterNotifierProvider =
    AsyncNotifierProvider.autoDispose<RosterNotifier, RosterEntry>(
  () => RosterNotifier(),
);