import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver.dart';
import '../services/driver_service.dart';

final driverServiceProvider = Provider((ref) => DriverService());

/// Stream provider for a driver document by uid.
final driverProvider = StreamProvider.family<DriverModel?, String>((ref, uid) {
  return ref.watch(driverServiceProvider).watchDriver(uid);
});
