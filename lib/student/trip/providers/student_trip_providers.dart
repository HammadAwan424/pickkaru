import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/shared/trip/services/shared_trip_service.dart';
import 'package:pickkaru/shared/trip/providers/shared_trip_providers.dart';
import 'package:pickkaru/shared/trip/providers/active_trip_logic.dart';
import 'package:pickkaru/shared/date/format_date.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/shared/trip/utils/trip_resolver.dart';

// 1. STUDENT TRIPS (List)
typedef StudentTripArgs = ({String driverId, String studentId});
final studentTripsProvider = StreamProvider.autoDispose.family<List<TripModel>, StudentTripArgs>((ref, args) {
  return ref.watch(sharedTripServiceProvider).watchStudentTrips(args.driverId, args.studentId);
});

// 2. STUDENT SINGLE TRIP
typedef StudentSingleTripArgs = ({String driverId, String studentId, String tripId});
final studentSingleTripProvider = Provider.autoDispose.family<AsyncValue<TripModel?>, StudentSingleTripArgs>((ref, args) {
  return ref.watch(studentTripsProvider((driverId: args.driverId, studentId: args.studentId))).whenData(
    (trips) => trips.where((t) => t.id == args.tripId).firstOrNull
  );
});

// 3. STUDENT ACTIVE TRIP
final studentActiveTripProvider = Provider.autoDispose.family<AsyncValue<ActiveTripState?>, StudentTripArgs>((ref, args) {
  final today = ref.watch(todayDateProvider);
  return computeActiveTripState(
    tripsAsync: ref.watch(studentTripsProvider(args)),
    tripRunsAsync: ref.watch(tripRunProvider((driverId: args.driverId, dateString: formatDate(today)))),
    today: today,
  );
});

// ==========================================
// STRICT PROVIDERS (Derived from Auth Chain)
// ==========================================

final requireStudentTripsProvider = Provider.autoDispose<List<TripModel>>((ref) {
  final student = ref.watch(requireStudentProvider);
  final uid = ref.watch(requireAuthStateProvider).user.uid;
  final async = ref.watch(studentTripsProvider((
    driverId: student.assignedDriverId,
    studentId: uid,
  )));
  return async.when(
    data: (trips) => trips,
    loading: () => throw StateError('Student trips still loading'),
    error: (e, s) => throw e,
  );
});

final requireStudentActiveTripProvider = Provider.autoDispose<ActiveTripState>((ref) {
  final student = ref.watch(requireStudentProvider);
  final uid = ref.watch(requireAuthStateProvider).user.uid;
  final async = ref.watch(studentActiveTripProvider((
    driverId: student.assignedDriverId,
    studentId: uid,
  )));
  return async.when(
    data: (v) => v ?? (throw StateError('No active trip computed')),
    loading: () => throw StateError('Active trip still loading'),
    error: (e, s) => throw e,
  );
});

final requireStudentTripRunProvider = Provider.autoDispose<TripRunDay?>((ref) {
  final active = ref.watch(requireStudentActiveTripProvider);
  final student = ref.watch(requireStudentProvider);
  final dateStr = formatDate(active.date);
  final async = ref.watch(tripRunProvider((
    driverId: student.assignedDriverId,
    dateString: dateStr,
  )));
  return async.when(
    data: (v) => v,
    loading: () => throw StateError('Trip run still loading'),
    error: (e, s) => throw e,
  );
});

final requireStudentResponseProvider = Provider.autoDispose.family<TripLegResponse?, TripLegDirection>((ref, direction) {
  final active = ref.watch(requireStudentActiveTripProvider);
  final student = ref.watch(requireStudentProvider);
  final dateStr = formatDate(active.date);
  final async = ref.watch(tripResponseProvider((
    driverId: student.assignedDriverId,
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

final requireStudentDefaultsProvider = Provider.autoDispose.family<TripLegConfig?, TripLegDirection>((ref, direction) {
  final active = ref.watch(requireStudentActiveTripProvider);
  final student = ref.watch(requireStudentProvider);
  final async = ref.watch(tripDefaultsProvider((
    driverId: student.assignedDriverId,
    tripId: active.trip.id,
    direction: direction,
  )));
  return async.when(
    data: (v) => v,
    loading: () => throw StateError('Defaults still loading'),
    error: (e, s) => throw e,
  );
});

final requireStudentResolvedLegProvider = Provider.autoDispose.family<CoreStudentLegData?, TripLegDirection>((ref, direction) {
  final student = ref.watch(requireStudentProvider);
  final active = ref.watch(requireStudentActiveTripProvider);
  final dateStr = formatDate(active.date);
  
  final config = ref.watch(requireStudentDefaultsProvider(direction));
  final response = ref.watch(requireStudentResponseProvider(direction));
  
  return resolveStudentLegData(
    studentId: student.uid,
    dateString: dateStr,
    config: config,
    response: response,
  );
});
