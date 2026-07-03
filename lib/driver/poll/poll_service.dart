import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/shared/poll/models/PollConfig.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';
import 'package:pickkaru/shared/poll/models/PrivateOverride.dart';
import 'package:pickkaru/shared/date/format_date.dart';

class DriverPollService {
  DriverPollService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Map<String, dynamic> _generateInitialResponse({
    required PollPeriod period,
    required bool defaultMorning,
    required bool defaultEvening,
    required String? defaultCheckpoint,
    PrivateOverride? override,
  }) {
    final bool resolvedAnswer = period == PollPeriod.morning
        ? (override?.morningAnswer ?? defaultMorning)
        : (override?.eveningAnswer ?? defaultEvening);

    return {
      'answer': resolvedAnswer,
      if (period == PollPeriod.evening && defaultCheckpoint != null)
        'checkpoint': defaultCheckpoint,
      'boarded': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DocumentReference<Map<String, dynamic>> _responsesRef(
    PollArgs args,
    String date,
  ) {
    return _db.collection(args.responsesPath).doc(date);
  }


  Future<void> startRide(PollArgs args) async {
    await _db.doc(args.pollConfigPath).update({
      'status': PollStatus.active.firestoreValue,
    });
  }

  Future<void> completeRide({
    required PollArgs args,
    required DateTime date,
  }) async {
    final batch = _db.batch();

    // 1. Mark current ride completed
    batch.update(_db.doc(args.pollConfigPath), {
      'status': PollStatus.completed.firestoreValue,
    });

    // 2. If completing evening, initialize tomorrow's rides atomically
    if (args.period == PollPeriod.evening) {
      final tomorrow = date.add(const Duration(days: 1));
      try {
        await initializeDailyBoard(
          args: PollArgs(driverId: args.driverId, period: PollPeriod.morning),
          date: tomorrow,
          batch: batch,
        );
      } catch (e) {
        // Handle gracefully if roster or overrides does not exist
      }
      try {
        await initializeDailyBoard(
          args: PollArgs(driverId: args.driverId, period: PollPeriod.evening),
          date: tomorrow,
          batch: batch,
        );
      } catch (e) {
        // Handle gracefully
      }
    }

    await batch.commit();
  }


  Future<void> addApproachingStudent({
    required PollArgs args,
    required String studentId,
    required DateTime date,
  }) async {
    final dateStr = formatDate(date);
    await _responsesRef(args, dateStr).update({
      'approachingStudentIds': FieldValue.arrayUnion([studentId]),
    });
  }


  // ── Daily Board Initialization ──

  Future<void> initializeDailyBoard({
    required PollArgs args,
    required DateTime date,
    WriteBatch? batch,
  }) async {
    final dateStr = formatDate(date);
    
    // 1. Fetch Roster defaults
    final rosterDoc = await _db.collection('rosters').doc(args.driverId).get();
    final rosterData = rosterDoc.data();
    
    final studentsData = <String, Map<String, dynamic>>{};
    final todayOverrides = <String, PrivateOverride>{};
    
    if (rosterData != null && rosterData['students'] != null) {
      final studentsMap = Map<String, dynamic>.from(rosterData['students'] as Map);
      
      final futures = <Future<MapEntry<String, DocumentSnapshot<Map<String, dynamic>>>>>[];

      for (final studentId in studentsMap.keys) {
        studentsData[studentId] = Map<String, dynamic>.from(studentsMap[studentId] as Map);
        
        // 2. Queue override fetch concurrently
        final future = _db
            .collection('students')
            .doc(studentId)
            .collection('overrides')
            .doc(dateStr)
            .get()
            .then((doc) => MapEntry(studentId, doc));
        futures.add(future);
      }

      final results = await Future.wait(futures);
      for (final entry in results) {
        final studentId = entry.key;
        final overrideDoc = entry.value;
        if (overrideDoc.exists && overrideDoc.data() != null) {
          todayOverrides[studentId] = PrivateOverride.fromMap(overrideDoc.data()!);
        }
      }
    }
    
    // 3. Initialize/Merge Daily Poll
    await initializeDailyPoll(
      args: args,
      date: dateStr,
      studentsData: studentsData,
      todayOverrides: todayOverrides,
      batch: batch,
    );
  }

  Future<void> initializeDailyPoll({
    required PollArgs args,
    required String date,
    required Map<String, Map<String, dynamic>> studentsData,
    required Map<String, PrivateOverride> todayOverrides,
    WriteBatch? batch,
  }) async {
    final responses = <String, dynamic>{};

    for (final entry in studentsData.entries) {
      final studentId = entry.key;
      final data = entry.value;
      final override = todayOverrides[studentId];

      final responseMap = _generateInitialResponse(
        period: args.period,
        defaultMorning: data['defaultMorning'] as bool? ?? false,
        defaultEvening: data['defaultEvening'] as bool? ?? false,
        defaultCheckpoint: data['defaultCheckpoint'] as String?,
        override: override,
      );

      responses[studentId] = responseMap;
    }

    final docRef = _responsesRef(args, date);
    final updates = {
      'responses': responses,
      // If the document doesn't exist, we must provide approachingStudentIds
      // We'll use merge, so if it does exist, this will just overwrite with empty if we sent empty.
      // Actually, merge: true only merges nested fields if they are maps. For arrays, it replaces.
      // We shouldn't overwrite approachingStudentIds if the doc already exists!
      // But we can just set responses map. We don't need approachingStudentIds if we're just merging responses.
    };

    if (batch != null) {
      batch.set(docRef, {'responses': responses}, SetOptions(merge: true));
    } else {
      await docRef.set({'responses': responses}, SetOptions(merge: true));
    }
  }

}

final driverPollServiceProvider = Provider<DriverPollService>((ref) {
  return DriverPollService();
});
