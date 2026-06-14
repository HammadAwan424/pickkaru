import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/poll.dart';

class PollService {
  PollService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── Parent Config: polls/{driverId}_{period} ──

  String _pollId(String driverId, PollPeriod period) =>
      '${driverId}_${period.firestoreId}';

  DocumentReference<Map<String, dynamic>> _pollRef(
    String driverId,
    PollPeriod period,
  ) {
    return _db.collection('polls').doc(_pollId(driverId, period));
  }

  DocumentReference<Map<String, dynamic>> _responsesRef(
    String driverId,
    PollPeriod period,
    String date,
  ) {
    return _pollRef(driverId, period).collection('responses').doc(date);
  }

  Stream<Poll?> watchPoll({
    required String driverId,
    required PollPeriod period,
  }) {
    return _pollRef(driverId, period).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Poll.fromMap(
        snap.data()!,
        fallbackPeriod: period,
      );
    });
  }

  Stream<DriverPolls> watchDriverPolls(String driverId) {
    return _db
        .collection('polls')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final pollsById = {
        for (final doc in snapshot.docs)
          doc.id: Poll.fromMap(
            doc.data(),
            fallbackPeriod: PollPeriodFirestore.fromFirestore(
              doc.id.split('_').last,
            ),
          ),
      };

      return DriverPolls(
        morning: pollsById[_pollId(driverId, PollPeriod.morning)] ??
            Poll.empty(PollPeriod.morning),
        evening: pollsById[_pollId(driverId, PollPeriod.evening)] ??
            Poll.empty(PollPeriod.evening),
      );
    });
  }

  Future<void> startRide({
    required String driverId,
    required PollPeriod period,
  }) async {
    // 1. Fetch Roster defaults
    final rosterDoc = await _db.collection('rosters').doc(driverId).get();
    final rosterData = rosterDoc.data();
    
    final studentDefaults = <String, bool>{};
    final studentDefaultCheckpoints = <String, String?>{};
    final todayOverrides = <String, PrivateOverride>{};
    
    final todayStr = _formatDate(DateTime.now());
    
    if (rosterData != null && rosterData['students'] != null) {
      final studentsMap = Map<String, dynamic>.from(rosterData['students'] as Map);
      
      for (final studentId in studentsMap.keys) {
        final studentData = Map<String, dynamic>.from(studentsMap[studentId] as Map);
        
        // Extract default morning/evening answers based on period
        final defaultAnswer = period == PollPeriod.morning
            ? (studentData['defaultMorning'] as bool? ?? false)
            : (studentData['defaultEvening'] as bool? ?? false);
            
        studentDefaults[studentId] = defaultAnswer;
        studentDefaultCheckpoints[studentId] = studentData['defaultCheckpoint'] as String?;
        
        // 2. Fetch Override for student for today
        final overrideDoc = await _db
            .collection('students')
            .doc(studentId)
            .collection('overrides')
            .doc(todayStr)
            .get();
            
        if (overrideDoc.exists && overrideDoc.data() != null) {
          todayOverrides[studentId] = PrivateOverride.fromMap(overrideDoc.data()!);
        }
      }
    }
    
    // 3. Initialize/Merge Daily Poll
    await initializeDailyPoll(
      driverId: driverId,
      period: period,
      date: todayStr,
      studentDefaults: studentDefaults,
      studentDefaultCheckpoints: studentDefaultCheckpoints,
      todayOverrides: todayOverrides,
    );

    // 4. Update status
    await _pollRef(driverId, period).update({
      'status': PollStatus.active.firestoreValue,
    });
  }

  Future<void> completeRide({
    required String driverId,
    required PollPeriod period,
  }) async {
    await _pollRef(driverId, period).update({
      'status': PollStatus.completed.firestoreValue,
    });
  }

  // ── Shared Daily Board: polls/{id}/responses/{date} ──

  Stream<Poll?> watchDailyBoard({
    required String driverId,
    required PollPeriod period,
    required DateTime date,
  }) {
    final dateStr = _formatDate(date);
    return _responsesRef(driverId, period, dateStr).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Poll.fromResponsesMap(
        period: period,
        data: snap.data()!,
      );
    });
  }

  Future<void> updateStudentResponse({
    required String driverId,
    required PollPeriod period,
    required String studentId,
    required DateTime date,
    bool? answer,
    bool updateAnswer = true,
    String? checkpoint,
    bool updateCheckpoint = false,
  }) async {
    final dateStr = _formatDate(date);
    final updates = <String, dynamic>{
      if (updateAnswer) 'responses.$studentId.answer': answer,
      if (period == PollPeriod.evening && updateCheckpoint)
        'responses.$studentId.checkpoint': checkpoint,
      'responses.$studentId.updatedAt': FieldValue.serverTimestamp(),
    };

    await _responsesRef(driverId, period, dateStr).update(
      updates,
    );
  }

  Future<void> setStudentBoarded({
    required String driverId,
    required PollPeriod period,
    required String studentId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    await _responsesRef(driverId, period, dateStr).update({
      'responses.$studentId.boarded': true,
      'responses.$studentId.updatedAt': FieldValue.serverTimestamp(),
    });
    await _responsesRef(driverId, period, dateStr).update({
      'approachingStudentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  Future<void> addApproachingStudent({
    required String driverId,
    required PollPeriod period,
    required String studentId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    await _responsesRef(driverId, period, dateStr).update({
      'approachingStudentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  // ── Private Overrides (Days 1-6) ──

  Future<void> updateFutureOverride({
    required String studentId,
    required DateTime date,
    bool? morningAnswer,
    bool? eveningAnswer,
    String? eveningCheckpoint,
  }) async {
    final dateStr = _formatDate(date);
    final overrideRef =
        _db.collection('students').doc(studentId).collection('overrides').doc(dateStr);

    final existingSnap = await overrideRef.get();
    if (!existingSnap.exists && morningAnswer == null && eveningAnswer == null) {
      return;
    }

    final data = <String, dynamic>{};
    if (morningAnswer != null) {
      data['morning'] = {'answer': morningAnswer};
    }
    if (eveningAnswer != null || eveningCheckpoint != null) {
      data['evening'] = {
        if (eveningAnswer != null) 'answer': eveningAnswer,
        if (eveningCheckpoint != null) 'checkpoint': eveningCheckpoint,
      };
    }

    if (data.isEmpty) {
      await overrideRef.delete();
      return;
    }

    await overrideRef.set(data, SetOptions(merge: true));
  }

  Future<void> deleteFutureOverride({
    required String studentId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    await _db
        .collection('students')
        .doc(studentId)
        .collection('overrides')
        .doc(dateStr)
        .delete();
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

  // ── Daily Board Initialization ──

  Future<void> initializeDailyPoll({
    required String driverId,
    required PollPeriod period,
    required String date,
    required Map<String, bool> studentDefaults,
    required Map<String, String?> studentDefaultCheckpoints,
    required Map<String, PrivateOverride> todayOverrides,
  }) async {
    final responses = <String, dynamic>{};

    for (final entry in studentDefaults.entries) {
      final studentId = entry.key;
      final defaultAnswer = entry.value;
      final override = todayOverrides[studentId];

      bool? resolvedAnswer;
      String? resolvedCheckpoint;

      if (period == PollPeriod.morning) {
        resolvedAnswer = override?.morningAnswer ?? defaultAnswer;
      } else {
        resolvedAnswer = override?.eveningAnswer ?? defaultAnswer;
        resolvedCheckpoint =
            override?.eveningCheckpoint ?? studentDefaultCheckpoints[studentId];
      }

      responses[studentId] = {
        'answer': resolvedAnswer,
        if (period == PollPeriod.evening && resolvedCheckpoint != null)
          'checkpoint': resolvedCheckpoint,
        'boarded': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };
    }

    await _responsesRef(driverId, period, date).set({
      'responses': responses,
      'approachingStudentIds': <String>[],
    });
  }

  // ── Helpers ──

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
