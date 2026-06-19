import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../student.dart';
import '../../../shared/roster/roster.dart';
import '../services/student_service.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/roster/roster_provider.dart';

final studentServiceProvider = Provider((ref) => StudentService());

/// Stream provider for a student document by uid, combined with defaults from their driver's roster.
final studentProvider = StreamProvider.family<StudentModel?, String>((ref, uid) {
  return ref.watch(studentServiceProvider).watchStudent(uid);
});
