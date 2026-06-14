class RosterEntry {
  final String displayName;
  final bool defaultMorning;
  final bool defaultEvening;
  final String? defaultCheckpoint;

  const RosterEntry({
    required this.displayName,
    required this.defaultMorning,
    required this.defaultEvening,
    this.defaultCheckpoint,
  });

  factory RosterEntry.fromMap(Map<String, dynamic> map) {
    return RosterEntry(
      displayName: map['displayName'] as String? ?? '',
      defaultMorning: map['defaultMorning'] as bool? ?? false,
      defaultEvening: map['defaultEvening'] as bool? ?? false,
      defaultCheckpoint: map['defaultCheckpoint'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'defaultMorning': defaultMorning,
      'defaultEvening': defaultEvening,
      'defaultCheckpoint': defaultCheckpoint,
    };
  }
}

class Roster {
  final String driverId;
  final Map<String, RosterEntry> students;

  const Roster({
    required this.driverId,
    required this.students,
  });

  factory Roster.fromMap(String driverId, Map<String, dynamic> map) {
    final rawStudents = map['students'] as Map<String, dynamic>? ?? {};
    return Roster(
      driverId: driverId,
      students: rawStudents.map((studentId, value) => MapEntry(
            studentId,
            RosterEntry.fromMap(Map<String, dynamic>.from(value as Map)),
          )),
    );
  }
}
