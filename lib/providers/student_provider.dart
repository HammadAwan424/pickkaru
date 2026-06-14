import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../models/roster.dart';
import '../services/student_service.dart';
import 'auth_provider.dart';
import 'roster_provider.dart';

final studentServiceProvider = Provider((ref) => StudentService());

/// Stream provider for a student document by uid, combined with defaults from their driver's roster.
final studentProvider = StreamProvider.family<StudentModel?, String>((ref, uid) {
  final controller = StreamController<StudentModel?>();
  
  StreamSubscription? studentSub;
  StreamSubscription? rosterSub;
  
  StudentModel? currentStudent;
  
  void updateCombined(StudentModel? student, Roster? roster) {
    if (student == null) {
      if (!controller.isClosed) controller.add(null);
      return;
    }
    if (student.assignedDriverId == null) {
      if (!controller.isClosed) controller.add(student);
      return;
    }
    final entry = roster?.students[uid];
    if (!controller.isClosed) {
      controller.add(StudentModel(
        uid: student.uid,
        assignedDriverId: student.assignedDriverId,
        defaultMorning: entry?.defaultMorning ?? false,
        defaultEvening: entry?.defaultEvening ?? false,
        defaultCheckpoint: entry?.defaultCheckpoint,
      ));
    }
  }
  
  studentSub = ref.watch(studentServiceProvider).watchStudent(uid).listen((student) {
    currentStudent = student;
    if (rosterSub != null) {
      rosterSub!.cancel();
      rosterSub = null;
    }
    
    if (student != null && student.assignedDriverId != null) {
      rosterSub = ref.watch(rosterServiceProvider).watchRoster(student.assignedDriverId!).listen((roster) {
        updateCombined(currentStudent, roster);
      }, onError: (err) {
        if (!controller.isClosed) controller.addError(err);
      });
    } else {
      updateCombined(student, null);
    }
  }, onError: (err) {
    if (!controller.isClosed) controller.addError(err);
  });
  
  ref.onDispose(() {
    studentSub?.cancel();
    rosterSub?.cancel();
    controller.close();
  });
  
  return controller.stream;
});

final settingsNotifierProvider = AsyncNotifierProvider<SettingsNotifier, void>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateDisplayName(String newDisplayName) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      throw StateError('User is not authenticated.');
    }
    
    final student = ref.read(studentProvider(user.uid)).valueOrNull;
    final driverId = student?.assignedDriverId;
    if (driverId == null) {
      throw StateError('Student is not assigned to a driver.');
    }
    
    await ref.read(studentServiceProvider).updateDisplayName(
      uid: user.uid,
      assignedDriverId: driverId,
      newDisplayName: newDisplayName,
    );
  }
}