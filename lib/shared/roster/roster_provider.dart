import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/roster/Roster.dart';
import 'package:pickkaru/shared/roster/roster_service.dart';

final rosterProvider = StreamProvider.family<Roster?, String>((ref, driverId) {
  return ref.watch(sharedRosterServiceProvider).watchLocalRoster(driverId);
});
