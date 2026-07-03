import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studentRosterServiceProvider = Provider((ref) => StudentRosterService());

class StudentRosterService {
  final _db = FirebaseFirestore.instance;

  Future<void> updateStudentDefaults({
    required String driverId,
    required String studentId,
    bool? morning,
    bool? evening,
    String? checkpoint,
  }) async {
    final updates = <String, dynamic>{
      if (morning != null) 'students.$studentId.defaultMorning': morning,
      if (evening != null) 'students.$studentId.defaultEvening': evening,
      if (checkpoint != null) 'students.$studentId.defaultCheckpoint': checkpoint,
    };

    if (updates.isEmpty) return; // Nothing to do!

    await _db.collection('rosters').doc(driverId).update(updates);
  }
}
