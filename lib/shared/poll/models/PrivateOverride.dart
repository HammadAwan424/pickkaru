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