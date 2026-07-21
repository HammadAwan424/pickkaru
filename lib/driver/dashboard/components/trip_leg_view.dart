import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/driver/trip/providers/driver_trip_providers.dart';

import 'trip_stats_card.dart';
import 'student_trip_card.dart';

class TripLegView extends ConsumerWidget {
  final TripModel trip;
  final TripLegDirection direction;
  final DateTime date;
  final bool isTripStarted;
  final bool isTripCompleted;

  const TripLegView({
    super.key,
    required this.trip,
    required this.direction,
    required this.date,
    required this.isTripStarted,
    required this.isTripCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (trip.participants.isEmpty) {
      return const Center(child: Text('No students assigned to this trip.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      children: [
        TripStatsCard(
          studentIds: trip.participants,
          direction: direction,
        ),
        const SizedBox(height: 24),
        
        const Text(
          'Student List',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...trip.participants.map((studentId) {
          return Consumer(
            builder: (context, ref, child) {
              final resolvedData = ref.watch(requireDriverResolvedLegProvider((
                studentId: studentId,
                direction: direction,
              )));

              // If null, the student has no active config for this leg
              if (resolvedData == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: StudentTripCard(
                  studentId: studentId,
                  legData: resolvedData,
                  direction: direction,
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
