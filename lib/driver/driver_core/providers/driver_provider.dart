import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Driver.dart';
import '../services/driver_service.dart';


import '../../../core/auth/auth_provider.dart';

/// Stream provider for the logged-in driver's document.
final driverProvider = StreamProvider<DriverModel?>((ref) {
  final authData = ref.watch(authStateProvider).valueOrNull;
  if (authData == null) return Stream.value(null);
  
  if (authData.claims['role'] == 'student') return Stream.value(null);

  return ref.watch(driverServiceProvider).watchLocalDriver(authData.user.uid);
});

// ==========================================
// STRICT PROVIDERS (Derived from Auth Chain)
// ==========================================

// Strict Driver Document
final requireDriverProvider = Provider<DriverModel>((ref) {
  final driver = ref.watch(driverProvider).valueOrNull;
  if (driver == null) {
    throw StateError('requireDriverProvider accessed but driver document is null.');
  }
  return driver;
});
