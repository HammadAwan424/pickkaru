enum StudentInitType { unassigned, assigned }

sealed class StudentProfile {
  final String uid;
  final StudentInitType initType;

  const StudentProfile({
    required this.uid,
    required this.initType,
  });

  Map<String, dynamic> _commonMap() => {
    'uid': uid,
    'initType': initType.name,
  };

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    final type = StudentInitType.values.byName(map['initType'] as String);
    return switch (type) {
      StudentInitType.unassigned => UnassignedStudentProfile.fromMap(map),
      StudentInitType.assigned => AssignedStudentProfile.fromMap(map),
    };
  }

  Map<String, dynamic> toMap();
}

class UnassignedStudentProfile extends StudentProfile {
  const UnassignedStudentProfile({
    required super.uid,
  }) : super(initType: StudentInitType.unassigned); // Hardcoded safely

  factory UnassignedStudentProfile.fromMap(Map<String, dynamic> map) {
    return UnassignedStudentProfile(
      uid: map['uid'] as String,
    );
  }

  Map<String, dynamic> toMap() => _commonMap();
}

class AssignedStudentProfile extends StudentProfile {
  final String assignedDriverId;

  const AssignedStudentProfile({
    required super.uid,
    required this.assignedDriverId,
  }) : super(initType: StudentInitType.assigned); // Hardcoded safely

  factory AssignedStudentProfile.fromMap(Map<String, dynamic> map) {
    return AssignedStudentProfile(
      uid: map['uid'] as String,
      assignedDriverId: map['assignedDriverId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    ..._commonMap(),
    'assignedDriverId': assignedDriverId,
  };
}