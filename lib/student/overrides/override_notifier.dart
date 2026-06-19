import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/poll/models/DailyPollBoard.dart';
import 'package:pickkaru/student/overrides/override_provider.dart';

final overrideNotifierProvider = NotifierProvider.autoDispose.family<OverrideNotifier, bool?, OverrideNotifierArgs>(
  OverrideNotifier.new,
);

@immutable
class OverrideNotifierArgs {
  final String studentId;
  final DateTime date;
  final PollPeriod period;
  final bool? initialValue;

  const OverrideNotifierArgs({
    required this.studentId,
    required this.date,
    required this.period,
    this.initialValue,
  });

  @override
  bool operator ==(Object other) {
    return other is OverrideNotifierArgs &&
        other.studentId == studentId &&
        other.date == date &&
        other.period == period;
  }

  @override
  int get hashCode => Object.hash(studentId, date, period);
}

class OverrideNotifier extends AutoDisposeFamilyNotifier<bool?, OverrideNotifierArgs> {
  @override
  bool? build(OverrideNotifierArgs arg) {
    return arg.initialValue;
  }

  Future<void> updateValue(bool? newValue) async {
    if (state == newValue) return; // if value is the same, dont do anything
    
    final previousValue = state;
    state = newValue;
    
    try {
      await ref.read(overrideServiceProvider).updateFutureOverride(
        studentId: arg.studentId,
        date: arg.date,
        period: arg.period,
        value: newValue,
      );
    } catch (e) {
      state = previousValue;
      rethrow;
    }
  }
}