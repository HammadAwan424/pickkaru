import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../services/student_service.dart';

final studentServiceProvider = Provider((ref) => StudentService());

/// Stream provider for a student document by uid.
final studentProvider = StreamProvider.family<StudentModel?, String>((ref, uid) {
  return ref.watch(studentServiceProvider).watchStudent(uid);
});
