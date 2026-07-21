import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/driver/trip/providers/driver_trip_providers.dart';

class TripStatsCard extends ConsumerWidget {
  final List<String> studentIds;
  final TripLegDirection direction;

  const TripStatsCard({
    super.key,
    required this.studentIds,
    required this.direction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int ridingCount = 0;
    int notRidingCount = 0;
    int boardedCount = 0; // Requires tracking boarded state in the future (perhaps in TripRunDay or responses)

    for (var id in studentIds) {
      final data = ref.watch(requireDriverResolvedLegProvider((
        studentId: id,
        direction: direction,
      )));
      
      if (data != null) {
        if (data.vote) {
          ridingCount++;
          // if (data.boarded) boardedCount++; // Future implementation
        } else {
          notRidingCount++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Riding',
            count: ridingCount,
            color: const Color(0xFF0D9488),
          ),
          _StatDivider(),
          _StatItem(
            label: 'Not Riding',
            count: notRidingCount,
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
