class DriverModel {
  final String uid;
  final List<String> assignedStudents;
  final Map<String, PublicStudentRosterEntry> publicStudentRoster;
  final String refreshTime;

  DriverModel({
    required this.uid,
    required this.assignedStudents,
    required this.publicStudentRoster,
    required this.refreshTime,
  });

  factory DriverModel.fromMap(String uid, Map<String, dynamic> map) {
    final rawRoster =
        Map<String, dynamic>.from(map['publicStudentRoster'] ?? {});

    return DriverModel(
      uid: uid,
      assignedStudents: List<String>.from(map['assignedStudents'] ?? <String>[]),
      publicStudentRoster: rawRoster.map((studentId, value) {
        return MapEntry(
          studentId,
          PublicStudentRosterEntry.fromMap(
            Map<String, dynamic>.from(value as Map),
          ),
        );
      }),
      refreshTime: map['refreshTime'] as String? ?? '19:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedStudents': assignedStudents,
      'publicStudentRoster': publicStudentRoster.map(
        (studentId, entry) => MapEntry(studentId, entry.toMap()),
      ),
      'refreshTime': refreshTime,
    };
  }
}

class PublicStudentRosterEntry {
  final String displayName;
  final String? pickupAreaPublic;

  const PublicStudentRosterEntry({
    required this.displayName,
    required this.pickupAreaPublic,
  });

  factory PublicStudentRosterEntry.fromMap(Map<String, dynamic> map) {
    return PublicStudentRosterEntry(
      displayName: map['displayName'] as String? ?? '',
      pickupAreaPublic: map['pickupAreaPublic'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'pickupAreaPublic': pickupAreaPublic,
    };
  }
}