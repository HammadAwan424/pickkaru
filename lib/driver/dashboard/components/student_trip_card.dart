import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/shared/roster/roster_provider.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';

class StudentTripCard extends ConsumerWidget {
  final String studentId;
  final CoreStudentLegData legData;
  final TripLegDirection direction;

  const StudentTripCard({
    super.key,
    required this.studentId,
    required this.legData,
    required this.direction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverId = ref.watch(requireAuthStateProvider).user.uid;
    final rosterAsync = ref.watch(rosterProvider(driverId));
    
    final displayName = rosterAsync.valueOrNull?.students[studentId]?.displayName ?? 'Loading...';

    // UI State variables
    final isRiding = legData.vote;
    final cardColor = isRiding ? Colors.white : Colors.grey.shade100;
    final titleColor = isRiding ? const Color(0xFF1F2937) : Colors.grey.shade500;
    
    String subtitle = isRiding ? 'Going' : 'Not Going';
    
    // Display extra info based on leg data type
    if (isRiding) {
      if (legData is DriverStudentLegData) {
        final cp = (legData as DriverStudentLegData).checkpoint;
        subtitle = 'Checkpoint: $cp';
      } else if (legData is SimpleStudentLegData) {
        subtitle = 'Fixed/Custom Route';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: isRiding
            ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isRiding ? const Color(0xFF0D9488).withOpacity(0.1) : Colors.grey.shade200,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color: isRiding ? const Color(0xFF0D9488) : Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isRiding ? const Color(0xFF4B5563) : Colors.grey.shade400,
            fontSize: 13,
          ),
        ),
        trailing: isRiding
            ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
            : const Icon(Icons.cancel, color: Colors.grey),
      ),
    );
  }
}
