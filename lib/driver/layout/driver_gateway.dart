import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';
import 'package:pickkaru/driver/trip/providers/driver_trip_providers.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';
import 'driver_shell.dart';

class DriverGateway extends ConsumerWidget {
  const DriverGateway({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(driverProvider);
    
    return driverAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Center(child: Text('Error loading driver profile: $e', style: const TextStyle(color: Colors.red))),
      ),
      data: (driver) {
        if (driver == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF3F4F6),
            body: Center(child: Text('Driver profile not found. Please contact support.', style: TextStyle(color: Colors.red))),
          );
        }
        final uid = ref.read(requireAuthStateProvider).user.uid;
        return _ActiveTripGate(driverId: uid);
      },
    );
  }
}

class _ActiveTripGate extends ConsumerWidget {
  final String driverId;
  const _ActiveTripGate({required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(driverActiveTripProvider(driverId));
    return activeAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
          ),
        ),
      ),
      error: (e, stack) => Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Center(child: Text('Error loading trips: $e', style: const TextStyle(color: Colors.red))),
      ),
      data: (activeState) {
        if (activeState == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF3F4F6),
            body: Center(child: Text('You have no trips configured yet.', style: TextStyle(color: Colors.red))),
          );
        }
        return const DriverShell();
      },
    );
  }
}
