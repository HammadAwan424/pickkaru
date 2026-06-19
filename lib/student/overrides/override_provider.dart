import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/poll/models/DailyPollBoard.dart';
import 'package:pickkaru/student/overrides/override_service.dart';

final overrideServiceProvider = Provider<OverrideService>((ref) {
  return OverrideService();
});

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
  return ref.watch(overrideServiceProvider).watchOverride(
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
  return ref.watch(overrideServiceProvider).watchOverridesForWeek(
        studentId: args.studentId,
        start: args.start,
      );
});