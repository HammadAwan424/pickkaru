class DriverModel {
  final String uid;
  final List<String> assignedStudents;
  final String refreshTime;

  DriverModel({
    required this.uid,
    required this.assignedStudents,
    required this.refreshTime,
  });

  factory DriverModel.fromMap(String uid, Map<String, dynamic> map) {
    return DriverModel(
      uid: uid,
      assignedStudents: List<String>.from(map['assignedStudents'] ?? <String>[]),
      refreshTime: map['refreshTime'] as String? ?? '19:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedStudents': assignedStudents,
      'refreshTime': refreshTime,
    };
  }
}
