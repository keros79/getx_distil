/// Domain-layer entity for a user. Deliberately free of JSON / serialization
/// concerns — the Data layer maps DTOs into this (see `UserRepositoryImpl`).
class UserEntity {
  final int id;
  final String name;
  final String email;

  const UserEntity({required this.id, required this.name, required this.email});
}
