import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/date/format_date.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import '../../shared/poll/models/PrivateOverride.dart';

// student opens override page
// sees default/yes/no
// changes a value press enters
// if value is the same, dont do anything
// if value changes: (service assumes this statement)
// default (represented by void) -> emit delete
// yes/no -> emit set with merge true since the document may not exist

class OverrideService {
  final FirebaseFirestore _db;

  OverrideService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> updateFutureOverride({
    required String studentId,
    required DateTime date,
    required PollPeriod period,
    required bool? value,
  }) async {
    final dateStr = formatDate(date);
    final overrideRef =
        _db.collection('students').doc(studentId).collection('overrides').doc(dateStr);

    final fieldName = period == PollPeriod.morning ? 'morning' : 'evening';
    final updates = <String, dynamic>{
      fieldName: value == null ? FieldValue.delete() : {'answer': value},
    };

    await overrideRef.set(updates, SetOptions(merge: true));
  }

  Stream<List<MapEntry<DateTime, PrivateOverride>>> watchLocalOverridesForWeek({
    required String studentId,
    required DateTime start,
  }) {
    final end = start.add(const Duration(days: 6));
    final startStr = formatDate(start);
    final endStr = formatDate(end);

    return _db
        .collection('students')
        .doc(studentId)
        .collection('overrides')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endStr)
        .snapshots(source: ListenSource.cache)
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

final overrideServiceProvider = Provider<OverrideService>((ref) {
  return OverrideService();
});