class PrivateOverride {
  final bool? morningAnswer;
  final bool? eveningAnswer;

  const PrivateOverride({
    this.morningAnswer,
    this.eveningAnswer,
  });

  factory PrivateOverride.fromMap(Map<String, dynamic> map) {
    return PrivateOverride(
      morningAnswer: map['morning']?['answer'] as bool?,
      eveningAnswer: map['evening']?['answer'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (morningAnswer != null) 'morning': {'answer': morningAnswer},
      if (eveningAnswer != null) 'evening': {'answer': eveningAnswer},
    };
  }

  PrivateOverride copyWith({
    bool? morningAnswer,
    bool? eveningAnswer,
  }) {
    return PrivateOverride(
      morningAnswer: morningAnswer ?? this.morningAnswer,
      eveningAnswer: eveningAnswer ?? this.eveningAnswer,
    );
  }
}