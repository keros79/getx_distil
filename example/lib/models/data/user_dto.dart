import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Data-layer DTO returned by the REST API.
///
/// Demo endpoint: `GET https://jsonplaceholder.typicode.com/users/1`.
@freezed
abstract class UserDto with _$UserDto {
  const factory UserDto({
    required int id,
    required String name,
    required String email,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}
