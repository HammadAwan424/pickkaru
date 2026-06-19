class DriverModel {
  final String uid;
  final List<String> assignedStudents;
  final String refreshTime;
  final String timeZoneName;

  DriverModel({
    required this.uid,
    required this.assignedStudents,
    required this.refreshTime,
    required this.timeZoneName,
  });

  factory DriverModel.fromMap(String uid, Map<String, dynamic> map) {
    return DriverModel(
      uid: uid,
      assignedStudents: List<String>.from(map['assignedStudents'] ?? <String>[]),
      refreshTime: map['refreshTime'] as String? ?? '19:00',
      timeZoneName: map['timeZoneName'] as String? ?? 'Asia/Karachi',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedStudents': assignedStudents,
      'refreshTime': refreshTime,
      'timeZoneName': timeZoneName,
    };
  }
}