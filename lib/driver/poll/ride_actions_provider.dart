import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/driver/poll/poll_provider.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';
import 'package:pickkaru/shared/date/current_date_provider.dart';
import 'package:pickkaru/shared/poll/models/PollConfig.dart';

class RideActionException implements Exception {
  final String message;
  RideActionException(this.message);
  @override
  String toString() => message;
}

class RideActions extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> startMorningRide() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final driverId = _getAuthenticatedDriverId();
      _getValidatedActiveDate(PollPeriod.morning);
      
      final pollService = ref.read(driverPollServiceProvider);
      await pollService.startRide(PollArgs(driverId: driverId, period: PollPeriod.morning));
    });
  }

  Future<void> startEveningRide() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final driverId = _getAuthenticatedDriverId();
      _getValidatedActiveDate(PollPeriod.evening);
      _validateMorningCompleted();
      
      final pollService = ref.read(driverPollServiceProvider);
      await pollService.startRide(PollArgs(driverId: driverId, period: PollPeriod.evening));
    });
  }

  Future<void> completeMorningRide() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final driverId = _getAuthenticatedDriverId();
      final activeDate = _getValidatedActiveDate(PollPeriod.morning);
      
      final pollService = ref.read(driverPollServiceProvider);
      await pollService.completeRide(
        args: PollArgs(driverId: driverId, period: PollPeriod.morning),
        date: activeDate,
      );
    });
  }

  Future<void> completeEveningRide() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final driverId = _getAuthenticatedDriverId();
      final activeDate = _getValidatedActiveDate(PollPeriod.evening);
      
      final pollService = ref.read(driverPollServiceProvider);
      await pollService.completeRide(
        args: PollArgs(driverId: driverId, period: PollPeriod.evening),
        date: activeDate,
      );
    });
  }

  // --- Reusable Validation Rules ---

  String _getAuthenticatedDriverId() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || user.username == null) {
      throw RideActionException('Driver not authenticated.');
    }
    return user.username!;
  }

  DateTime _getValidatedActiveDate(PollPeriod period) {
    final activeDate = ref.read(driverActiveDateProvider(period)).valueOrNull;
    final currentDate = ref.read(currentDateProvider);

    if (activeDate == null || !_isSameDay(activeDate, currentDate)) {
      throw RideActionException('Cannot perform action for a past or future date.');
    }
    return activeDate;
  }

  void _validateMorningCompleted() {
    final morningConfig = ref.read(driverWatchPollConfigProvider(PollPeriod.morning)).valueOrNull;
    if (morningConfig == null || morningConfig.status != PollStatus.completed) {
      throw RideActionException('Morning ride must be completed first.');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final rideActionsProvider = AsyncNotifierProvider.autoDispose<RideActions, void>(() {
  return RideActions();
});
