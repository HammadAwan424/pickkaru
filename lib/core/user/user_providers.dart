import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});
