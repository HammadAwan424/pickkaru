class StudentModel {
  final String uid;
  final String? assignedDriverId;
  final bool defaultMorning;
  final bool defaultEvening;
  final String? defaultCheckpoint;

  StudentModel({
    required this.uid,
    this.assignedDriverId,
    this.defaultMorning = false,
    this.defaultEvening = false,
    this.defaultCheckpoint,
  });

  factory StudentModel.fromMap(String uid, Map<String, dynamic> map) {
    return StudentModel(
      uid: uid,
      assignedDriverId: map['assignedDriverId'] as String?,
      defaultMorning: map['defaultMorning'] as bool? ?? false,
      defaultEvening: map['defaultEvening'] as bool? ?? false,
      defaultCheckpoint: map['defaultCheckpoint'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedDriverId': assignedDriverId,
      'defaultMorning': defaultMorning,
      'defaultEvening': defaultEvening,
      'defaultCheckpoint': defaultCheckpoint,
    };
  }
}
