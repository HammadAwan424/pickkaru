import '../enums.dart';

sealed class UserProfile {
  final String uid;
  final String displayName;
  final String username;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.username,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    if (map.containsKey('role') && map['role'] != null) {
      return UserModel(
        uid: uid,
        role: roles.values.byName(map['role'] as String),
        displayName: map['displayName'] as String? ?? '',
        username: map['username'] as String? ?? '',
      );
    }
    return PendingUserProfile(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      username: map['username'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap();
}

class PendingUserProfile extends UserProfile {
  const PendingUserProfile({
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

class UserModel extends UserProfile {
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
