import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/roster.dart';
import '../services/roster_service.dart';

final rosterServiceProvider = Provider((ref) => RosterService());

final rosterProvider =
    StreamProvider.family<Roster?, String>((ref, driverId) {
  return ref.watch(rosterServiceProvider).watchRoster(driverId);
});
