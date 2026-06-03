import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/poll.dart';

class PollService {
  PollService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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
        .collection('drivers')
        .doc(driverId)
        .collection('polls')
        .snapshots()
        .map((snapshot) {
      final pollsById = {
        for (final doc in snapshot.docs)
          doc.id: Poll.fromMap(
            doc.data(),
            fallbackPeriod: PollPeriodFirestore.fromFirestore(doc.id),
          ),
      };

      return DriverPolls(
        morning: pollsById[PollPeriod.morning.firestoreId] ??
            Poll.empty(PollPeriod.morning),
        evening: pollsById[PollPeriod.evening.firestoreId] ??
            Poll.empty(PollPeriod.evening),
      );
    });
  }

  Future<void> updateStudentResponse({
    required String driverId,
    required PollPeriod period,
    required String studentId,
    bool? answer,
    bool updateAnswer = true,
    String? checkpoint,
    bool updateCheckpoint = false,
  }) async {
    final updates = <String, dynamic>{
      if (updateAnswer) 'responses.$studentId.answer': answer,
      if (period == PollPeriod.evening && updateCheckpoint)
        'responses.$studentId.checkpoint': checkpoint,
      'responses.$studentId.updatedAt': FieldValue.serverTimestamp(),
    };

    await _pollRef(driverId, period).update(updates);
  }

  Future<void> setStudentBoarded({
    required String driverId,
    required PollPeriod period,
    required String studentId,
  }) async {
    await _pollRef(driverId, period).update({
      'responses.$studentId.boarded': true,
      'responses.$studentId.updatedAt': FieldValue.serverTimestamp(),
      'approachingStudentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  Future<void> addApproachingStudent({
    required String driverId,
    required PollPeriod period,
    required String studentId,
  }) async {
    await _pollRef(driverId, period).update({
      'approachingStudentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  DocumentReference<Map<String, dynamic>> _pollRef(
    String driverId,
    PollPeriod period,
  ) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('polls')
        .doc(period.firestoreId);
  }
}
