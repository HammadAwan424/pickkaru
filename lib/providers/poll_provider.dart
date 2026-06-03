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

final pollActionsProvider = Provider<PollActions>((ref) {
  return PollActions(ref);
});

class PollActions {
  PollActions(this._ref);

  final Ref _ref;

  Future<void> updateStudentResponse({
    required String driverId,
    required PollPeriod period,
    required String studentId,
    bool? answer,
    bool updateAnswer = true,
    String? checkpoint,
    bool updateCheckpoint = false,
  }) {
    return _ref.read(pollServiceProvider).updateStudentResponse(
          driverId: driverId,
          period: period,
          studentId: studentId,
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
  }) {
    final poll = _readPoll(driverId: driverId, period: period);
    final response = poll.responses[studentId];

    if (response == null) {
      throw StateError('Student response does not exist for this poll.');
    }

    if (response.boarded) {
      return Future.value();
    }

    return _ref.read(pollServiceProvider).setStudentBoarded(
          driverId: driverId,
          period: period,
          studentId: studentId,
        );
  }

  Future<String?> markNextStudentApproaching({
    required String driverId,
    required PollPeriod period,
  }) async {
    final driver = _ref.read(driverProvider(driverId)).value;
    final poll = _readPoll(driverId: driverId, period: period);

    if (driver == null) {
      throw StateError('Driver is not loaded.');
    }

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
            );
        return studentId;
      }
    }

    return null;
  }

  Poll _readPoll({
    required String driverId,
    required PollPeriod period,
  }) {
    final poll = _ref
        .read(pollProvider(PollStreamArgs(driverId: driverId, period: period)))
        .value;

    if (poll == null) {
      throw StateError('Poll is not loaded.');
    }

    return poll;
  }
}
