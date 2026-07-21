import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Student.dart';
import '../services/student_service.dart';

import '../../../core/auth/auth_provider.dart';

/// Stream provider for the logged-in student's document.
final studentProvider = StreamProvider<StudentProfile?>((ref) {
  final authData = ref.watch(authStateProvider).valueOrNull;
  if (authData == null) return Stream.value(null);
  
  if (authData.claims['role'] == 'driver') return Stream.value(null);

  return ref.watch(studentServiceProvider).watchLocalStudent(authData.user.uid);
});

// ==========================================
// STRICT PROVIDERS (Derived from Auth Chain)
// ==========================================

// Strict Student Document (No Network Waterfall!)
final requireStudentProvider = Provider<AssignedStudentProfile>((ref) {
  final student = ref.watch(studentProvider).valueOrNull;
  if (student == null) {
    throw StateError('requireStudentProvider accessed but student document is null.');
  }
  if (student is UnassignedStudentProfile) {
    throw StateError('requireStudentProvider accessed but student is unassigned.');
  }
  return student as AssignedStudentProfile;
});
