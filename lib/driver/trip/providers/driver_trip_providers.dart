import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/shared/trip/services/shared_trip_service.dart';
import 'package:pickkaru/shared/trip/providers/shared_trip_providers.dart';
import 'package:pickkaru/shared/trip/providers/active_trip_logic.dart';
import 'package:pickkaru/shared/date/format_date.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/shared/trip/utils/trip_resolver.dart';

// 1. DRIVER TRIPS (List)
final driverTripsProvider = StreamProvider.autoDispose.family<List<TripModel>, String>((ref, driverId) {
  return ref.watch(sharedTripServiceProvider).watchDriverTrips(driverId);
});

// 2. DRIVER SINGLE TRIP
typedef SingleTripArgs = ({String driverId, String tripId});
final driverSingleTripProvider = Provider.autoDispose.family<AsyncValue<TripModel?>, SingleTripArgs>((ref, args) {
  return ref.watch(driverTripsProvider(args.driverId)).whenData(
    (trips) => trips.where((t) => t.id == args.tripId).firstOrNull
  );
});

// 3. DRIVER ACTIVE TRIP
final driverActiveTripProvider = Provider.autoDispose.family<AsyncValue<ActiveTripState?>, String>((ref, driverId) {
  final today = ref.watch(todayDateProvider);
  return computeActiveTripState(
    tripsAsync: ref.watch(driverTripsProvider(driverId)),
    tripRunsAsync: ref.watch(tripRunProvider((driverId: driverId, dateString: formatDate(today)))),
    today: today,
  );
});

// ==========================================
// STRICT PROVIDERS (Derived from Auth Chain)
// ==========================================

final requireDriverTripsProvider = Provider.autoDispose<List<TripModel>>((ref) {
  final driverId = ref.watch(requireAuthStateProvider).user.uid;
  final async = ref.watch(driverTripsProvider(driverId));
  return async.when(
    data: (trips) => trips,
    loading: () => throw StateError('Driver trips still loading'),
    error: (e, s) => throw e,
  );
});

final requireDriverActiveTripProvider = Provider.autoDispose<ActiveTripState>((ref) {
  final driverId = ref.watch(requireAuthStateProvider).user.uid;
  final async = ref.watch(driverActiveTripProvider(driverId));
  return async.when(
    data: (v) => v ?? (throw StateError('No active trip computed')),
    loading: () => throw StateError('Active trip still loading'),
    error: (e, s) => throw e,
  );
});

final requireDriverTripRunProvider = Provider.autoDispose<TripRunDay?>((ref) {
  final driverId = ref.watch(requireAuthStateProvider).user.uid;
  final active = ref.watch(requireDriverActiveTripProvider);
  final dateStr = formatDate(active.date);
  final async = ref.watch(tripRunProvider((
    driverId: driverId,
    dateString: dateStr,
  )));
  return async.when(
    data: (v) => v,
    loading: () => throw StateError('Trip run still loading'),
    error: (e, s) => throw e,
  );
});

final requireDriverResponseProvider = Provider.autoDispose.family<TripLegResponse?, TripLegDirection>((ref, direction) {
  final driverId = ref.watch(requireAuthStateProvider).user.uid;
  final active = ref.watch(requireDriverActiveTripProvider);
  final dateStr = formatDate(active.date);
  final async = ref.watch(tripResponseProvider((
    driverId: driverId,
    tripId: active.trip.id,
    direction: direction,
    dateString: dateStr,
  )));
  return async.when(
    data: (v) => v,
    loading: () => throw StateError('Response still loading'),
    error: (e, s) => throw e,
  );
});

final requireDriverDefaultsProvider = Provider.autoDispose.family<TripLegConfig?, TripLegDirection>((ref, direction) {
  final driverId = ref.watch(requireAuthStateProvider).user.uid;
  final active = ref.watch(requireDriverActiveTripProvider);
  final async = ref.watch(tripDefaultsProvider((
    driverId: driverId,
    tripId: active.trip.id,
    direction: direction,
  )));
  return async.when(
    data: (v) => v,
    loading: () => throw StateError('Defaults still loading'),
    error: (e, s) => throw e,
  );
});

typedef DriverResolvedLegArgs = ({String studentId, TripLegDirection direction});

final requireDriverResolvedLegProvider = Provider.autoDispose.family<CoreStudentLegData?, DriverResolvedLegArgs>((ref, args) {
  final active = ref.watch(requireDriverActiveTripProvider);
  final dateStr = formatDate(active.date);
  
  final config = ref.watch(requireDriverDefaultsProvider(args.direction));
  final response = ref.watch(requireDriverResponseProvider(args.direction));
  
  return resolveStudentLegData(
    studentId: args.studentId,
    dateString: dateStr,
    config: config,
    response: response,
  );
});
