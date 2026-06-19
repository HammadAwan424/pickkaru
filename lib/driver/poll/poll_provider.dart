import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/driver/poll/poll_service.dart';
import 'package:pickkaru/shared/poll/poll_provider.dart';
import 'package:pickkaru/shared/poll/models/DailyPollBoard.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PollConfig.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';

final driverPollServiceProvider = Provider<DriverPollService>((ref) {
  return DriverPollService();
});

final driverWatchPollConfigProvider = Provider.autoDispose.family<AsyncValue<PollConfig?>, PollPeriod>((ref, period) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AsyncValue.data(null);
  final driverId = user.username;
  
  return ref.watch(sharedWatchPollConfigProvider(PollArgs(driverId: driverId, period: period)));
});

final driverDailyBoardProvider = Provider.autoDispose.family<AsyncValue<DailyPollBoard?>, PollPeriod>((ref, period) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AsyncValue.data(null);
  final driverId = user.username;
  
  return ref.watch(sharedDailyBoardProvider(PollArgs(driverId: driverId, period: period)));
});

final driverActiveDateProvider = Provider.autoDispose.family<AsyncValue<DateTime?>, PollPeriod>((ref, period) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AsyncValue.data(null);
  final driverId = user.username;
  
  return ref.watch(sharedActiveDateProvider(PollArgs(driverId: driverId, period: period)));
});
