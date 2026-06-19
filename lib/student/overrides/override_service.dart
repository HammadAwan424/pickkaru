import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/poll/models/DailyPollBoard.dart';

// student opens override page
// sees default/yes/no
// changes a value press enters
// if value is the same, dont do anything
// if value changes: (service assumes this statement)
// default -> emit delete
// yes/no -> emit set with merge true since the document may not exist

class OverrideService {
  final FirebaseFirestore _db;

  OverrideService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> updateFutureOverride({
    required String studentId,
    required DateTime date,
    required PollPeriod period,
    required bool? value,
  }) async {
    final dateStr = _formatDate(date);
    final overrideRef =
        _db.collection('students').doc(studentId).collection('overrides').doc(dateStr);

    final fieldName = period == PollPeriod.morning ? 'morning' : 'evening';

    if (value == null) {
      await overrideRef.set({
        fieldName: FieldValue.delete(),
      }, SetOptions(merge: true));
    } else {
      await overrideRef.set({
        fieldName: {'answer': value},
      }, SetOptions(merge: true));
    }
  }

  Stream<PrivateOverride?> watchOverride({
    required String studentId,
    required DateTime date,
  }) {
    final dateStr = _formatDate(date);
    return _db
        .collection('students')
        .doc(studentId)
        .collection('overrides')
        .doc(dateStr)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return PrivateOverride.fromMap(snap.data()!);
    });
  }

  Stream<List<MapEntry<DateTime, PrivateOverride>>> watchOverridesForWeek({
    required String studentId,
    required DateTime start,
  }) {
    final end = start.add(const Duration(days: 6));
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);

    return _db
        .collection('students')
        .doc(studentId)
        .collection('overrides')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endStr)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MapEntry(
          DateTime.parse(doc.id),
          PrivateOverride.fromMap(doc.data()),
        );
      }).toList();
    });
  }
}
