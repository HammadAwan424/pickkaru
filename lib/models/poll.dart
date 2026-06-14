import 'package:cloud_firestore/cloud_firestore.dart';

enum PollPeriod {
  morning,
  evening,
}

enum PollStatus {
  uninitiated,
  active,
  completed;

  String get firestoreValue => name;
  static PollStatus fromFirestore(String value) {
    return PollStatus.values.byName(value);
  }
}

extension PollPeriodFirestore on PollPeriod {
  String get firestoreId => name;

  static PollPeriod fromFirestore(String value) {
    return PollPeriod.values.byName(value);
  }
}

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

class Poll {
  final PollPeriod period;
  final PollStatus status;
  final List<String>? checkpoints;
  final Map<String, PollResponse> responses;
  final List<String> approachingStudentIds;

  const Poll({
    required this.period,
    required this.status,
    required this.checkpoints,
    required this.responses,
    required this.approachingStudentIds,
  });

  factory Poll.fromMap(Map<String, dynamic> map, {PollPeriod? fallbackPeriod}) {
    final periodValue = map['period'] as String?;
    final period = periodValue == null
        ? fallbackPeriod ?? PollPeriod.morning
        : PollPeriodFirestore.fromFirestore(periodValue);

    final statusValue = map['status'] as String?;
    final status = statusValue == null
        ? PollStatus.uninitiated
        : PollStatus.fromFirestore(statusValue);

    final rawResponses = map['responses'] as Map<String, dynamic>? ?? {};
    final responses = rawResponses.map((studentId, value) {
      return MapEntry(
        studentId,
        PollResponse.fromMap(Map<String, dynamic>.from(value as Map)),
      );
    });

    return Poll(
      period: period,
      status: status,
      checkpoints: map['checkpoints'] == null
          ? null
          : List<String>.from(map['checkpoints'] as List),
      responses: responses,
      approachingStudentIds:
          List<String>.from(map['approachingStudentIds'] ?? <String>[]),
    );
  }

  /// Creates a Poll from a daily board document (responses subcollection).
  /// These docs only have `responses` and `approachingStudentIds`.
  factory Poll.fromResponsesMap({
    required PollPeriod period,
    required Map<String, dynamic> data,
  }) {
    final rawResponses = data['responses'] as Map<String, dynamic>? ?? {};
    final responses = rawResponses.map((studentId, value) {
      return MapEntry(
        studentId,
        PollResponse.fromMap(Map<String, dynamic>.from(value as Map)),
      );
    });

    return Poll(
      period: period,
      status: PollStatus.active,
      checkpoints: period == PollPeriod.evening ? <String>[] : null,
      responses: responses,
      approachingStudentIds:
          List<String>.from(data['approachingStudentIds'] ?? <String>[]),
    );
  }

  factory Poll.empty(PollPeriod period) {
    return Poll(
      period: period,
      status: PollStatus.uninitiated,
      checkpoints: period == PollPeriod.evening ? <String>[] : null,
      responses: const {},
      approachingStudentIds: const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period.firestoreId,
      'status': status.firestoreValue,
      'checkpoints': checkpoints,
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

class DriverPolls {
  final Poll morning;
  final Poll evening;

  const DriverPolls({
    required this.morning,
    required this.evening,
  });

  Poll byPeriod(PollPeriod period) {
    return switch (period) {
      PollPeriod.morning => morning,
      PollPeriod.evening => evening,
    };
  }
}

class PrivateOverride {
  final bool? morningAnswer;
  final bool? eveningAnswer;
  final String? eveningCheckpoint;

  const PrivateOverride({
    this.morningAnswer,
    this.eveningAnswer,
    this.eveningCheckpoint,
  });

  factory PrivateOverride.fromMap(Map<String, dynamic> map) {
    return PrivateOverride(
      morningAnswer: map['morning']?['answer'] as bool?,
      eveningAnswer: map['evening']?['answer'] as bool?,
      eveningCheckpoint: map['evening']?['checkpoint'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (morningAnswer != null) 'morning': {'answer': morningAnswer},
      if (eveningAnswer != null || eveningCheckpoint != null)
        'evening': {
          if (eveningAnswer != null) 'answer': eveningAnswer,
          if (eveningCheckpoint != null) 'checkpoint': eveningCheckpoint,
        },
    };
  }

  PrivateOverride copyWith({
    bool? morningAnswer,
    bool? eveningAnswer,
    String? eveningCheckpoint,
  }) {
    return PrivateOverride(
      morningAnswer: morningAnswer ?? this.morningAnswer,
      eveningAnswer: eveningAnswer ?? this.eveningAnswer,
      eveningCheckpoint: eveningCheckpoint ?? this.eveningCheckpoint,
    );
  }
}
