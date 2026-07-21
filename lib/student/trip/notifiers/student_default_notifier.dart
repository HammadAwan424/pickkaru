import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/student/trip/services/student_trip_service.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';

typedef StudentDefaultArgs = ({String driverId, String tripId, TripLegDirection direction});

class StudentDefaultNotifier extends AutoDisposeFamilyAsyncNotifier<void, StudentDefaultArgs> {

  @override
  FutureOr<void> build(StudentDefaultArgs arg) {}

  Future<void> updateDefault({
    required CoreStudentLegData newValue,
    required DateTime today,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final studentId = ref.read(requireAuthStateProvider).user.uid;
      await ref.read(studentTripServiceProvider).updateStudentTripDefault(
        driverId: arg.driverId,
        tripId: arg.tripId,
        direction: arg.direction,
        studentId: studentId,
        newValue: newValue,
        today: today,
      );
    });
  }
}

final studentDefaultNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<StudentDefaultNotifier, void, StudentDefaultArgs>(
  StudentDefaultNotifier.new,
);
