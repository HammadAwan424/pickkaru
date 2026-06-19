import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';
import 'package:pickkaru/student/poll/poll_provider.dart';

typedef ResponseDraft = ({bool answer, String? checkpoint});

class ResponseFormNotifier extends AutoDisposeFamilyAsyncNotifier<ResponseDraft, PollPeriod> {
  @override
  FutureOr<ResponseDraft> build(PollPeriod period) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final studentId = user?.uid;
    if (studentId == null) return (answer: false, checkpoint: null);

    final board = ref.watch(studentDailyBoardProvider(period)).valueOrNull;
    final response = board?.responses[studentId];

    return (
      answer: response?.answer ?? false,
      checkpoint: response?.checkpoint,
    );
  }

  Future<void> updateResponse({
    required bool newAnswer,
    String? newCheckpoint,
  }) async {
    final currentState = state.value!;

    final answerChanged = newAnswer != currentState.answer;
    final checkpointChanged = newCheckpoint != currentState.checkpoint;

    if (!answerChanged && !checkpointChanged) return;

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
        newAnswer: answerChanged ? newAnswer : null,
        newCheckpoint: checkpointChanged ? newCheckpoint : null,
      );
      
      return (answer: newAnswer, checkpoint: newCheckpoint);
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
      
      // Return the current draft state so we don't lose the UI values
      final board = ref.read(studentDailyBoardProvider(arg)).valueOrNull;
      final response = board?.responses[studentId];
      return (
        answer: response!.answer!,
        checkpoint: response.checkpoint,
      );
    });
  }
}

final responseFormNotifierProvider = AsyncNotifierProvider.autoDispose.family<ResponseFormNotifier, ResponseDraft, PollPeriod>(() {
  return ResponseFormNotifier();
});
