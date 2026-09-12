import '../models/domain/user_entity.dart';
import '../models/domain/user_repository.dart';
import 'rest_api_client.dart';

/// Default [UserRepository] backed by the Retrofit client.
///
/// Maps DTOs (Data layer) into domain entities. Bound at the app root, so
/// screens only ever see the [UserRepository] abstraction.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required this.client});

  final RestApiClient client;

  @override
  Future<UserEntity> fetchUser() async {
    final dto = await client.fetchUser();
    return UserEntity(id: dto.id, name: dto.name, email: dto.email);
  }
}
