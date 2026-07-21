import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/shared/trip/services/shared_trip_service.dart';
import 'package:pickkaru/shared/trip/services/shared_checkpoint_service.dart';
import 'package:pickkaru/shared/trip/services/shared_trip_run_service.dart';

// --- CONFIG DEFAULTS ---
typedef TripDefaultsArgs = ({String driverId, String tripId, TripLegDirection direction});
final tripDefaultsProvider = StreamProvider.autoDispose.family<TripLegConfig?, TripDefaultsArgs>((ref, args) {
  return ref.watch(sharedTripServiceProvider).watchTripDefaults(args.driverId, args.tripId, args.direction);
});

// --- RESPONSES ---
typedef TripResponseArgs = ({String driverId, String tripId, TripLegDirection direction, String dateString});
final tripResponseProvider = StreamProvider.autoDispose.family<TripLegResponse?, TripResponseArgs>((ref, args) {
  return ref.watch(sharedTripServiceProvider).watchTripResponse(args.driverId, args.tripId, args.direction, args.dateString);
});

// --- CHECKPOINTS ---
final checkpointSetProvider = StreamProvider.autoDispose.family<CheckpointSet?, String>((ref, setId) {
  return ref.watch(sharedCheckpointServiceProvider).watchCheckpointSet(setId);
});

// --- TRIP RUNS ---
typedef TripRunArgs = ({String driverId, String dateString});
final tripRunProvider = StreamProvider.autoDispose.family<TripRunDay?, TripRunArgs>((ref, args) {
  return ref.watch(sharedTripRunServiceProvider).watchTripRunDay(args.driverId, args.dateString);
});

// --- REACTIVE TIME ---
final todayDateProvider = Provider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(nextMidnight.difference(now), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return DateTime(now.year, now.month, now.day);
});
