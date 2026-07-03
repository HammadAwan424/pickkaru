import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/student/overrides/override_service.dart';

class OverrideNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // State is void
  }

  Future<void> updateMorningAnswer(DateTime date, bool? value) async {
    await _updateAnswer(date: date, period: PollPeriod.morning, value: value);
  }

  Future<void> updateEveningAnswer(DateTime date, bool? value) async {
    await _updateAnswer(date: date, period: PollPeriod.evening, value: value);
  }

  Future<void> _updateAnswer({
    required DateTime date,
    required PollPeriod period,
    required bool? value,
  }) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) throw Exception('User not logged in');

    await AsyncValue.guard(() async {
      await ref.read(overrideServiceProvider).updateFutureOverride(
            studentId: user.uid,
            date: date,
            period: period,
            value: value,
          );
    });
  }
}

final overrideNotifierProvider =
    AsyncNotifierProvider.autoDispose<OverrideNotifier, void>(
  () => OverrideNotifier(),
);