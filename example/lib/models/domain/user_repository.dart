import 'user_entity.dart';

/// Repository contract for user data (Domain layer).
///
/// Screens depend on this abstraction, so tests can substitute a mock
/// repository via `BindingWidget` without touching production code.
abstract class UserRepository {
  Future<UserEntity> fetchUser();
}
