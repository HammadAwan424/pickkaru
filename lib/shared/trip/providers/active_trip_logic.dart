import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';

typedef ActiveTripState = ({TripModel trip, DateTime date});

AsyncValue<ActiveTripState?> computeActiveTripState({
  required AsyncValue<List<TripModel>> tripsAsync,
  required AsyncValue<TripRunDay?> tripRunsAsync,
  required DateTime today,
}) {
  if (tripsAsync.isLoading || tripRunsAsync.isLoading) return const AsyncValue.loading();
  if (tripsAsync.hasError) return AsyncValue.error(tripsAsync.error!, tripsAsync.stackTrace!);
  
  final trips = tripsAsync.value ?? [];
  if (trips.isEmpty) return const AsyncValue.data(null);
  
  final sortedTrips = List<TripModel>.from(trips)..sort((a, b) => a.sequence.compareTo(b.sequence));
  final runsDay = tripRunsAsync.value;
  
  final completedTripIds = runsDay?.trips.entries
      .where((e) => e.value.completedAt != null)
      .map((e) => e.key)
      .toSet() ?? {};
  
  final activeTrip = sortedTrips.firstWhere(
    (t) => !completedTripIds.contains(t.id),
    orElse: () => sortedTrips.first,
  );
  
  final allCompleted = sortedTrips.every((t) => completedTripIds.contains(t.id));
  final activeDate = allCompleted ? today.add(const Duration(days: 1)) : today;
  
  return AsyncValue.data((trip: activeTrip, date: activeDate));
}
