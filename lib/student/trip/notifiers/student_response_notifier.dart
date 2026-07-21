import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/student/trip/services/student_trip_service.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';

typedef StudentResponseArgs = ({String driverId, String tripId, TripLegDirection direction});

class StudentResponseNotifier extends AutoDisposeFamilyAsyncNotifier<void, StudentResponseArgs> {
  
  @override
  FutureOr<void> build(StudentResponseArgs arg) {}

  Future<void> submitResponse({
    required String dateString,
    required CoreStudentLegData coreData,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final studentId = ref.read(requireAuthStateProvider).user.uid;
      await ref.read(studentTripServiceProvider).submitStudentResponse(
        driverId: arg.driverId,
        tripId: arg.tripId,
        direction: arg.direction,
        dateString: dateString,
        studentId: studentId,
        coreData: coreData,
      );
    });
  }

  Future<void> markBoarded({required String dateString}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final studentId = ref.read(requireAuthStateProvider).user.uid;
      await ref.read(studentTripServiceProvider).markStudentBoarded(
        driverId: arg.driverId,
        tripId: arg.tripId,
        direction: arg.direction,
        dateString: dateString,
        studentId: studentId,
        boarded: true,
      );
    });
  }

  Future<void> markDroppedOff({required String dateString}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final studentId = ref.read(requireAuthStateProvider).user.uid;
      await ref.read(studentTripServiceProvider).markStudentDroppedOff(
        driverId: arg.driverId,
        tripId: arg.tripId,
        direction: arg.direction,
        dateString: dateString,
        studentId: studentId,
        droppedOff: true,
      );
    });
  }
}

final studentResponseNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<StudentResponseNotifier, void, StudentResponseArgs>(
  StudentResponseNotifier.new,
);
