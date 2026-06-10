import 'package:getx_distil/get.dart';

/// Controller demonstrating usage of [RxS] with auto-status tracking.
class RxSController extends GetxController {
  final user = RxS<User?>(null);

  void loadUser() {
    user.value = User(
      name: '김철수',
      email: 'chulsoo@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=chulsoo',
    );
  }

  void updateName() {
    user.update((current) {
      if (current != null) {
        return User(
          name: '${current.name}님',
          email: current.email,
          avatarUrl: current.avatarUrl,
        );
      }
      return current;
    });
  }

  void setNull() {
    user.value = null;
  }

  void simulateError() {
    user.error = '네트워크 연결에 실패했습니다';
    user.status = RxDataStatus.error;
  }

  void reset() {
    user.value = null;
    user.status = RxDataStatus.loading;
    user.error = null;
  }
}

/// Simple User model for demonstration.
class User {
  final String name;
  final String email;
  final String avatarUrl;

  const User({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });
}
