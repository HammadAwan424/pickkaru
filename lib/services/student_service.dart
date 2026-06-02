import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

// student_service.dart — Firestore student doc concerns
class StudentService {
  final _db = FirebaseFirestore.instance;

  Stream<StudentModel?> watchStudent(String uid) {
    return _db.collection('students').doc(uid).snapshots().map((snap) {
      return snap.exists ? StudentModel.fromMap(snap.id, snap.data()!) : null;
    });
  }
}
