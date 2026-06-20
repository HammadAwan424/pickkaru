import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pickkaru/shared/poll/models/PollConfig.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';
import 'package:pickkaru/shared/poll/models/PrivateOverride.dart';
import 'package:pickkaru/shared/date/format_date.dart';
import '../../shared/poll/models/DailyPollBoard.dart';

class DriverPollService {
  DriverPollService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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
    
    final studentDefaults = <String, bool>{};
    final studentDefaultCheckpoints = <String, String?>{};
    final todayOverrides = <String, PrivateOverride>{};
    
    if (rosterData != null && rosterData['students'] != null) {
      final studentsMap = Map<String, dynamic>.from(rosterData['students'] as Map);
      
      final futures = <Future<MapEntry<String, DocumentSnapshot<Map<String, dynamic>>>>>[];

      for (final studentId in studentsMap.keys) {
        final studentData = Map<String, dynamic>.from(studentsMap[studentId] as Map);
        
        // Extract default morning/evening answers based on period
        final defaultAnswer = args.period == PollPeriod.morning
            ? (studentData['defaultMorning'] as bool? ?? false)
            : (studentData['defaultEvening'] as bool? ?? false);
            
        studentDefaults[studentId] = defaultAnswer;
        studentDefaultCheckpoints[studentId] = studentData['defaultCheckpoint'] as String?;
        
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
      studentDefaults: studentDefaults,
      studentDefaultCheckpoints: studentDefaultCheckpoints,
      todayOverrides: todayOverrides,
      batch: batch,
    );
  }

  Future<void> initializeDailyPoll({
    required PollArgs args,
    required String date,
    required Map<String, bool> studentDefaults,
    required Map<String, String?> studentDefaultCheckpoints,
    required Map<String, PrivateOverride> todayOverrides,
    WriteBatch? batch,
  }) async {
    final responses = <String, dynamic>{};

    for (final entry in studentDefaults.entries) {
      final studentId = entry.key;
      final defaultAnswer = entry.value;
      final override = todayOverrides[studentId];

      bool? resolvedAnswer;
      String? resolvedCheckpoint;

      if (args.period == PollPeriod.morning) {
        resolvedAnswer = override?.morningAnswer ?? defaultAnswer;
      } else {
        resolvedAnswer = override?.eveningAnswer ?? defaultAnswer;
        resolvedCheckpoint = studentDefaultCheckpoints[studentId];
      }

      responses[studentId] = {
        'answer': resolvedAnswer,
        if (args.period == PollPeriod.evening && resolvedCheckpoint != null)
          'checkpoint': resolvedCheckpoint,
        'boarded': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };
    }

    final docRef = _responsesRef(args, date);
    final data = {
      'responses': responses,
      'approachingStudentIds': <String>[],
    };

    if (batch != null) {
      batch.set(docRef, data);
    } else {
      await docRef.set(data);
    }
  }

}
