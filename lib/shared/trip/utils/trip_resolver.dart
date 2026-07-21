import 'package:pickkaru/shared/trip/models/core_student_leg_data.dart';
import 'package:pickkaru/shared/trip/models/trip_leg_config.dart';
import 'package:pickkaru/shared/trip/models/trip_leg_response.dart';

/// Resolves the effective student trip data for a given date by combining:
/// 1. An explicit response for that day (if any).
/// 2. The pending default configuration (if its effectiveFrom date has arrived).
/// 3. The active default configuration.
CoreStudentLegData? resolveStudentLegData({
  required String studentId,
  required String dateString,
  required TripLegConfig? config,
  required TripLegResponse? response,
}) {
  // 1. Check if there's an explicit daily response first
  if (response != null) {
    if (response is PickupTripLegResponse) {
      final studentRes = response.students[studentId];
      if (studentRes != null) return studentRes.coreData;
    } else if (response is DropoffTripLegResponse) {
      final studentRes = response.students[studentId];
      if (studentRes != null) return studentRes.coreData;
    }
  }

  // 2. Fall back to configuration
  if (config != null) {
    final entry = config.students[studentId];
    if (entry != null) {
      // Check if pending configuration is effective
      final pendingEffectiveFrom = entry.pending.effectiveFrom;
      if (pendingEffectiveFrom.isNotEmpty && dateString.compareTo(pendingEffectiveFrom) >= 0) {
        return entry.pending.coreData;
      }
      // Otherwise, return active configuration
      return entry.active;
    }
  }

  // Student not found in config or response
  return null;
}
