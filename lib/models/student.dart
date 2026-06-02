class StudentModel {
  final String uid;
  final String? assignedDriverId;

  StudentModel({required this.uid, this.assignedDriverId});

  factory StudentModel.fromMap(String uid, Map<String, dynamic> map) {
    return StudentModel(
      uid: uid,
      assignedDriverId: map['assignedDriverId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedDriverId': assignedDriverId,
    };
  }
}
