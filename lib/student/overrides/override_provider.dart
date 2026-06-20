import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/shared/date/format_date.dart';
import 'package:pickkaru/shared/poll/models/PrivateOverride.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/student/poll/poll_provider.dart';
import 'package:pickkaru/student/overrides/override_service.dart';

final overrideServiceProvider = Provider<OverrideService>((ref) {
  return OverrideService();
});

final overridesForWeekProvider = StreamProvider<Map<String, PrivateOverride>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value({});

  // TODO: make some sense of this shit, we have to either use morning or evening
  // but there is no reason to prefer one over the other 
  // WHY THE HELL DID WE EVEN DECOPULED THEM?
  final activeDateAsync = ref.watch(studentActiveDateProvider(PollPeriod.morning));
  final activeDateVal = activeDateAsync.valueOrNull;
  if (activeDateVal == null) return Stream.value({});

  // Compute start date: active date + 1 day
  final startDate = activeDateVal.add(const Duration(days: 1));

  return ref.watch(overrideServiceProvider).watchOverridesForWeek(
        studentId: user.uid,
        start: startDate,
      ).map((entries) => {
        for (final entry in entries) formatDate(entry.key): entry.value,
      });
});

final dailyOverrideProvider = Provider.family<PrivateOverride?, DateTime>((ref, date) {
  final weekAsync = ref.watch(overridesForWeekProvider);
  return weekAsync.valueOrNull?[formatDate(date)];
});