import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/shared/poll/models/DailyPollBoard.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/poll_provider.dart';
import 'package:pickkaru/shared/poll/models/PollConfig.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';


final studentWatchPollConfigProvider = Provider.autoDispose
    .family<AsyncValue<PollConfig?>, PollPeriod>((ref, period) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AsyncValue.data(null);

  final studentDoc = ref.watch(studentProvider(user.uid)).value;
  final driverId = studentDoc?.assignedDriverId;

  if (driverId == null) {
    return const AsyncValue.data(null);
  }

  return ref.watch(sharedWatchPollConfigProvider(
      PollArgs(driverId: driverId, period: period)));
});
final studentDailyBoardProvider = Provider.autoDispose
    .family<AsyncValue<DailyPollBoard?>, PollPeriod>((ref, period) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AsyncValue.data(null);

  final studentDoc = ref.watch(studentProvider(user.uid)).value;
  final driverId = studentDoc?.assignedDriverId;

  if (driverId == null) {
    return const AsyncValue.data(null);
  }

  return ref.watch(
      sharedDailyBoardProvider(PollArgs(driverId: driverId, period: period)));
});

final studentActiveDateProvider = Provider.autoDispose
    .family<AsyncValue<DateTime?>, PollPeriod>((ref, period) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AsyncValue.data(null);

  final studentDoc = ref.watch(studentProvider(user.uid)).value;
  final driverId = studentDoc?.assignedDriverId;

  if (driverId == null) {
    return const AsyncValue.data(null);
  }

  return ref.watch(
      sharedActiveDateProvider(PollArgs(driverId: driverId, period: period)));
});

typedef ResponseDraft = ({bool answer, String? checkpoint});

final studentResponseProvider = Provider.autoDispose
    .family<ResponseDraft, PollPeriod>((ref, period) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final studentId = user?.uid;
  if (studentId == null) return (answer: false, checkpoint: null);

  final board = ref.watch(studentDailyBoardProvider(period)).valueOrNull;
  final response = board?.responses[studentId];

  return (
    answer: response?.answer ?? false,
    checkpoint: response?.checkpoint,
  );
});
