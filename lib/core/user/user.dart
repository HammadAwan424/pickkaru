import '../enums.dart';

class UserModel {
  final String uid;
  final roles? role;
  final String displayName;
  final String username;

  UserModel({
    required this.uid,
    this.role,
    required this.displayName,
    required this.username,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      role: map['role'] != null ? roles.values.byName(map['role'] as String) : null,
      displayName: map['displayName'] as String? ?? '',
      username: map['username'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (role != null) 'role': role!.name,
      'displayName': displayName,
      'username': username,
    };
  }
}
