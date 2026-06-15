import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/poll.dart';
import 'driver_provider.dart';
import '../services/poll_service.dart';

final pollServiceProvider = Provider<PollService>((ref) {
  return PollService();
});

final driverPollsProvider =
    StreamProvider.family<DriverPolls, String>((ref, driverId) {
  return ref.watch(pollServiceProvider).watchDriverPolls(driverId);
});

@immutable
class PollStreamArgs {
  final String driverId;
  final PollPeriod period;

  const PollStreamArgs({
    required this.driverId,
    required this.period,
  });

  @override
  bool operator ==(Object other) {
    return other is PollStreamArgs &&
        other.driverId == driverId &&
        other.period == period;
  }

  @override
  int get hashCode => Object.hash(driverId, period);
}

final pollProvider = StreamProvider.family<Poll?, PollStreamArgs>((ref, args) {
  return ref.watch(pollServiceProvider).watchPoll(
        driverId: args.driverId,
        period: args.period,
      );
});

// ── Daily Board Provider ──

@immutable
class DailyBoardArgs {
  final String driverId;
  final PollPeriod period;
  final DateTime date;

  const DailyBoardArgs({
    required this.driverId,
    required this.period,
    required this.date,
  });

  @override
  bool operator ==(Object other) {
    return other is DailyBoardArgs &&
        other.driverId == driverId &&
        other.period == period &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day;
  }

  @override
  int get hashCode => Object.hash(
        driverId,
        period,
        date.year,
        date.month,
        date.day,
      );
}

final dailyBoardProvider =
    StreamProvider.family<Poll?, DailyBoardArgs>((ref, args) {
  return ref.watch(pollServiceProvider).watchDailyBoard(
        driverId: args.driverId,
        period: args.period,
        date: args.date,
      );
});

final activeDateProvider = StreamProvider.family<DateTime, String>((ref, driverId) {
  return ref.watch(driverPollsProvider(driverId)).when(
    loading: () => Stream.value(DateTime.now()),
    error: (_, __) => Stream.value(DateTime.now()),
    data: (polls) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (polls.evening.status == PollStatus.completed) {
        return Stream.value(today.add(const Duration(days: 1)));
      }
      return Stream.value(today);
    },
  );
});

// ── Override Providers ──

@immutable
class OverrideStreamArgs {
  final String studentId;
  final DateTime date;

  const OverrideStreamArgs({
    required this.studentId,
    required this.date,
  });

  @override
  bool operator ==(Object other) {
    return other is OverrideStreamArgs &&
        other.studentId == studentId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(studentId, date);
}

final overrideProvider =
    StreamProvider.family<PrivateOverride?, OverrideStreamArgs>((ref, args) {
  return ref.watch(pollServiceProvider).watchOverride(
        studentId: args.studentId,
        date: args.date,
      );
});

@immutable
class OverrideWeekArgs {
  final String studentId;
  final DateTime start;

  const OverrideWeekArgs({
    required this.studentId,
    required this.start,
  });

  @override
  bool operator ==(Object other) {
    return other is OverrideWeekArgs &&
        other.studentId == studentId &&
        other.start == start;
  }

  @override
  int get hashCode => Object.hash(studentId, start);
}

final overridesForWeekProvider =
    StreamProvider.family<List<MapEntry<DateTime, PrivateOverride>>, OverrideWeekArgs>(
        (ref, args) {
  return ref.watch(pollServiceProvider).watchOverridesForWeek(
        studentId: args.studentId,
        start: args.start,
      );
});

// ── Poll Actions ──

final pollActionsProvider = Provider<PollActions>((ref) {
  return PollActions(ref);
});

class PollActions {
  PollActions(this._ref);

  final Ref _ref;

  Future<void> startRide({
    required String driverId,
    required PollPeriod period,
  }) {
    return _ref.read(pollServiceProvider).startRide(
          driverId: driverId,
          period: period,
        );
  }

  Future<void> completeRide({
    required String driverId,
    required PollPeriod period,
    required DateTime date,
  }) {
    return _ref.read(pollServiceProvider).completeRide(
          driverId: driverId,
          period: period,
          date: date,
        );
  }

  Future<void> initializeDailyBoard({
    required String driverId,
    required PollPeriod period,
    required DateTime date,
  }) {
    return _ref.read(pollServiceProvider).initializeDailyBoard(
          driverId: driverId,
          period: period,
          date: date,
        );
  }

  Future<void> updateStudentBoarded({
    required String driverId,
    required PollPeriod period,
    required String studentId,
    required DateTime date,
    required bool boarded,
  }) {
    return _ref.read(pollServiceProvider).updateStudentBoarded(
          driverId: driverId,
          period: period,
          studentId: studentId,
          date: date,
          boarded: boarded,
        );
  }

  Future<void> updateStudentResponse({
    required String driverId,
    required PollPeriod period,
    required String studentId,
    required DateTime date,
    bool? answer,
    bool updateAnswer = true,
    String? checkpoint,
    bool updateCheckpoint = false,
  }) {
    return _ref.read(pollServiceProvider).updateStudentResponse(
          driverId: driverId,
          period: period,
          studentId: studentId,
          date: date,
          answer: answer,
          updateAnswer: updateAnswer,
          checkpoint: checkpoint,
          updateCheckpoint: updateCheckpoint,
        );
  }

  Future<void> markStudentBoarded({
    required String driverId,
    required PollPeriod period,
    required String studentId,
    required DateTime date,
  }) {
    return _ref.read(pollServiceProvider).setStudentBoarded(
          driverId: driverId,
          period: period,
          studentId: studentId,
          date: date,
        );
  }

  Future<String?> markNextStudentApproaching({
    required String driverId,
    required PollPeriod period,
    required DateTime date,
  }) async {
    final driver = _ref.read(driverProvider(driverId)).value;
    if (driver == null) {
      throw StateError('Driver is not loaded.');
    }

    final poll = _readDailyBoard(
      driverId: driverId,
      period: period,
      date: date,
    );

    final approachingStudentIds = poll.approachingStudentIds.toSet();
    for (final studentId in driver.assignedStudents) {
      final response = poll.responses[studentId];
      final votedNo = response?.answer == false;
      final boarded = response?.boarded == true;
      final approaching = approachingStudentIds.contains(studentId);

      if (!votedNo && !boarded && !approaching) {
        await _ref.read(pollServiceProvider).addApproachingStudent(
              driverId: driverId,
              period: period,
              studentId: studentId,
              date: date,
            );
        return studentId;
      }
    }

    return null;
  }

  Future<void> updateFutureOverride({
    required String studentId,
    required DateTime date,
    bool? morningAnswer,
    bool updateMorning = false,
    bool? eveningAnswer,
    bool updateEvening = false,
  }) {
    return _ref.read(pollServiceProvider).updateFutureOverride(
          studentId: studentId,
          date: date,
          morningAnswer: morningAnswer,
          updateMorning: updateMorning,
          eveningAnswer: eveningAnswer,
          updateEvening: updateEvening,
        );
  }

  Future<void> deleteFutureOverride({
    required String studentId,
    required DateTime date,
  }) {
    return _ref.read(pollServiceProvider).deleteFutureOverride(
          studentId: studentId,
          date: date,
        );
  }

  Future<void> initializeDailyPoll({
    required String driverId,
    required PollPeriod period,
    required String date,
    required Map<String, bool> studentDefaults,
    required Map<String, String?> studentDefaultCheckpoints,
    required Map<String, PrivateOverride> todayOverrides,
  }) {
    return _ref.read(pollServiceProvider).initializeDailyPoll(
          driverId: driverId,
          period: period,
          date: date,
          studentDefaults: studentDefaults,
          studentDefaultCheckpoints: studentDefaultCheckpoints,
          todayOverrides: todayOverrides,
        );
  }

  Poll _readDailyBoard({
    required String driverId,
    required PollPeriod period,
    required DateTime date,
  }) {
    final poll = _ref
        .read(dailyBoardProvider(DailyBoardArgs(
          driverId: driverId,
          period: period,
          date: date,
        )))
        .value;

    if (poll == null) {
      throw StateError('Daily board is not loaded.');
    }

    return poll;
  }
}
