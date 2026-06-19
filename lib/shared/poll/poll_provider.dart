import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';
import 'package:pickkaru/shared/poll/poll_service.dart';
import 'package:pickkaru/shared/poll/models/DailyPollBoard.dart';
import 'package:pickkaru/shared/poll/models/PollConfig.dart';

final sharedPollServiceProvider = Provider<SharedPollService>((ref) {
  return SharedPollService();
});



final sharedDailyBoardProvider = StreamProvider.autoDispose.family<DailyPollBoard?, PollArgs>((ref, args) {
  final pollService = ref.watch(sharedPollServiceProvider);
  return pollService.watchDailyBoard(args);
});

final sharedWatchPollConfigProvider = StreamProvider.autoDispose.family<PollConfig?, PollArgs>((ref, args) {
  final pollService = ref.watch(sharedPollServiceProvider);
  return pollService.watchPollConfig(args);
});

final sharedActiveDateProvider = Provider.autoDispose.family<AsyncValue<DateTime?>, PollArgs>((ref, args) {
  final responseAsync = ref.watch(sharedDailyBoardProvider(args));
  return responseAsync.whenData((board) => board?.date);
});

