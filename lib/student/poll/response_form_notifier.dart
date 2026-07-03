import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/poll/poll_service.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';
import 'package:pickkaru/student/poll/poll_provider.dart';

class ResponseFormNotifier extends AutoDisposeFamilyAsyncNotifier<void, PollPeriod> {
  @override
  FutureOr<void> build(PollPeriod period) {}

  Future<void> updateResponse({
    required bool newAnswer,
    String? newCheckpoint,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider).valueOrNull;
      final studentId = user?.uid;
      if (studentId == null) throw Exception('No user authenticated');

      final studentDoc = ref.read(studentProvider(studentId)).valueOrNull;
      final driverId = studentDoc?.assignedDriverId;
      if (driverId == null) throw Exception('No driver assigned');

      final date = ref.read(studentActiveDateProvider(arg)).valueOrNull;
      if (date == null) throw Exception('No active date');

      final service = ref.read(studentPollServiceProvider);

      await service.updateStudentResponse(
        args: PollArgs(driverId: driverId, period: arg),
        studentId: studentId,
        date: date,
        newAnswer: newAnswer,
        newCheckpoint: newCheckpoint,
      );
    });
  }

  Future<void> markBoarded() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider).valueOrNull;
      final studentId = user?.uid;
      if (studentId == null) throw Exception('No user authenticated');

      final studentDoc = ref.read(studentProvider(studentId)).valueOrNull;
      final driverId = studentDoc?.assignedDriverId;
      if (driverId == null) throw Exception('No driver assigned');

      final date = ref.read(studentActiveDateProvider(arg)).valueOrNull;
      if (date == null) throw Exception('No active date');

      final service = ref.read(studentPollServiceProvider);

      await service.updateStudentBoarded(
        args: PollArgs(driverId: driverId, period: arg),
        studentId: studentId,
        date: date,
        boarded: true,
      );
    });
  }
}

final responseFormNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ResponseFormNotifier, void, PollPeriod>(() {
  return ResponseFormNotifier();
});
