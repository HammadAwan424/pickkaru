import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'roster.dart';
import 'roster_service.dart';

final rosterServiceProvider = Provider((ref) => SharedRosterService());

final rosterProvider =
    StreamProvider.family<Roster?, String>((ref, driverId) {
  return ref.watch(rosterServiceProvider).watchRoster(driverId);
});
