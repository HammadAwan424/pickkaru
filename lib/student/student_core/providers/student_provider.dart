import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Student.dart';
import '../services/student_service.dart';

/// Stream provider for a student document by uid, combined with defaults from their driver's roster.
final studentProvider = StreamProvider.family<StudentModel?, String>((ref, uid) {
  return ref.watch(studentServiceProvider).watchLocalStudent(uid);
});
