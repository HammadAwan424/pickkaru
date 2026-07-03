import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Driver.dart';
import '../services/driver_service.dart';


/// Stream provider for a driver document by uid.
final driverProvider = StreamProvider.family<DriverModel?, String>((ref, uid) {
  return ref.watch(driverServiceProvider).watchLocalDriver(uid);
});
