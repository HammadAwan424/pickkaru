import '../enums.dart';

sealed class BaseUserModel {
  final String uid;
  final String displayName;
  final String username;

  const BaseUserModel({
    required this.uid,
    required this.displayName,
    required this.username,
  });

  factory BaseUserModel.fromMap(String uid, Map<String, dynamic> map, {String? claimRole}) {
    final roleStr = claimRole ?? map['role'] as String?;
    if (roleStr != null && roleStr.isNotEmpty) {
      return UserModel(
        uid: uid,
        role: roles.values.byName(roleStr),
        displayName: map['displayName'] as String,
        username: map['username'] as String,
      );
    }
    return PendingUserModel(
      uid: uid,
      displayName: map['displayName'] as String,
      username: map['username'] as String,
    );
  }

  Map<String, dynamic> toMap();
}

class PendingUserModel extends BaseUserModel {
  const PendingUserModel({
    required super.uid,
    required super.displayName,
    required super.username,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'username': username,
    };
  }
}

class UserModel extends BaseUserModel {
  final roles role;

  const UserModel({
    required super.uid,
    required this.role,
    required super.displayName,
    required super.username,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'displayName': displayName,
      'username': username,
    };
  }
}
