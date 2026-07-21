import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/driver/trip/services/driver_trip_service.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';

class DriverTripRunNotifier extends AutoDisposeFamilyAsyncNotifier<void, String> {
  // family arg = dateString

  @override
  FutureOr<void> build(String dateString) {}

  Future<void> startTrip({required String tripId, required DateTime now}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final driverId = ref.read(requireAuthStateProvider).user.uid;
      await ref.read(driverTripServiceProvider).updateTripRunState(
        driverId: driverId,
        dateString: arg,
        tripId: tripId,
        startedAt: now,
        completedAt: null,
      );
    });
  }

  Future<void> completeTrip({required String tripId, required DateTime now}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final driverId = ref.read(requireAuthStateProvider).user.uid;
      await ref.read(driverTripServiceProvider).updateTripRunState(
        driverId: driverId,
        dateString: arg,
        tripId: tripId,
        startedAt: null,
        completedAt: now,
      );
    });
  }
}

final driverTripRunNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<DriverTripRunNotifier, void, String>(
  DriverTripRunNotifier.new,
);
