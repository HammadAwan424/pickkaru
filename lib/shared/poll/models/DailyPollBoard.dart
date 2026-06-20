import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';


class PollResponse {
  final bool? answer;
  final bool boarded;
  final String? checkpoint;
  final Timestamp? updatedAt;

  const PollResponse({
    required this.answer,
    required this.boarded,
    required this.checkpoint,
    required this.updatedAt,
  });

  factory PollResponse.fromMap(Map<String, dynamic> map) {
    return PollResponse(
      answer: map['answer'] as bool?,
      boarded: map['boarded'] as bool? ?? false,
      checkpoint: map['checkpoint'] as String?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap({required PollPeriod period}) {
    return {
      'answer': answer,
      if (period == PollPeriod.evening) 'checkpoint': checkpoint,
      'boarded': boarded,
      'updatedAt': updatedAt,
    };
  }
}



class DailyPollBoard {
  final Map<String, PollResponse> responses;
  final List<String> approachingStudentIds;
  final DateTime? date;

  const DailyPollBoard({
    required this.responses,
    required this.approachingStudentIds,
    this.date,
  });

  factory DailyPollBoard.fromMap(Map<String, dynamic> data, {DateTime? date}) {
    final rawResponses = data['responses'] as Map<String, dynamic>? ?? {};
    final responses = rawResponses.map((studentId, value) {
      return MapEntry(
        studentId,
        PollResponse.fromMap(Map<String, dynamic>.from(value as Map)),
      );
    });

    return DailyPollBoard(
      responses: responses,
      approachingStudentIds:
          List<String>.from(data['approachingStudentIds'] ?? <String>[]),
      date: date,
    );
  }

  factory DailyPollBoard.empty() {
    return const DailyPollBoard(
      responses: {},
      approachingStudentIds: [],
    );
  }

  Map<String, dynamic> toMap({required PollPeriod period}) {
    return {
      'responses': responses.map(
        (studentId, response) => MapEntry(
          studentId,
          response.toMap(period: period),
        ),
      ),
      'approachingStudentIds': approachingStudentIds,
    };
  }
}
