import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pickkaru/shared/poll/models/PollConfig.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PollArgs.dart';
import 'models/DailyPollBoard.dart';

class SharedPollService {
  SharedPollService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<PollConfig?> watchPollConfig(PollArgs args) {
    return _db.doc(args.pollConfigPath).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PollConfig.fromMap(snap.data()!, fallbackPeriod: args.period);
    });
  }


  Stream<DailyPollBoard?> watchDailyBoard(PollArgs args) {
    return _db.collection(args.responsesPath)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final date = DateTime.tryParse(doc.id);
      if (date == null) return null;
      
      return DailyPollBoard.fromMap(
        doc.data(),
        date: date,
      );
    });
  }


}