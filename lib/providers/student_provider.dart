import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import 'auth_provider.dart';

final studentServiceProvider = Provider((ref) => StudentService());

/// Stream provider for a student document by uid.
final studentProvider = StreamProvider.family<StudentModel?, String>((ref, uid) {
  return ref.watch(studentServiceProvider).watchStudent(uid);
});

final settingsNotifierProvider = AsyncNotifierProvider<SettingsNotifier, void>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateDisplayName(String newDisplayName) async {
    final user = ref.read(currentUserProvider).value!;
    final student = ref.read(studentProvider(user.uid)).value!; // student is fetched already
    
    await ref.read(studentServiceProvider).updateDisplayName(
      uid: user.uid,
      assignedDriverId: student.assignedDriverId!,
      newDisplayName: newDisplayName,
    );
  }
}