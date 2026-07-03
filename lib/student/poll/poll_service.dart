import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';
import 'package:pickkaru/shared/date/format_date.dart';

class PollService {
  PollService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _responsesRef(
    PollArgs args,
    String date,
  ) {
    return _db.collection(args.responsesPath).doc(date);
  }

  Future<void> updateStudentBoarded({
    required PollArgs args,
    required String studentId,
    required DateTime date,
    required bool boarded,
  }) async {
    final dateStr = formatDate(date);
    final batch = _db.batch();
    final ref = _responsesRef(args, dateStr);

    final updates = <String, dynamic>{
      'responses.$studentId.boarded': boarded,
      'responses.$studentId.updatedAt': FieldValue.serverTimestamp(),
    };

    if (boarded) {
      updates['approachingStudentIds'] = FieldValue.arrayRemove([studentId]);
    }
    batch.update(ref, updates);
    await batch.commit();
  }

  Future<void> updateStudentResponse({
    required PollArgs args,
    required String studentId,
    required DateTime date,
    bool? newAnswer,
    String? newCheckpoint,
  }) async {
    final updates = <String, dynamic>{
      if (newAnswer != null) 'responses.$studentId.answer': newAnswer,
      if (newCheckpoint != null)
        'responses.$studentId.checkpoint': newCheckpoint,
      'responses.$studentId.updatedAt': FieldValue.serverTimestamp(),
    };

    if (updates.length == 1) return; // Only contains updatedAt

    await _responsesRef(args, formatDate(date)).update(updates);
  }
}

final studentPollServiceProvider = Provider<PollService>((ref) {
  return PollService();
});