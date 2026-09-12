import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/data/user_dto.dart';

part 'rest_api_client.g.dart';

/// Shared [Dio] for the whole app.
///
/// Demo scope: timeouts only. An auth/refresh interceptor would be attached
/// here in a real app.
Dio createDio() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}

/// Retrofit client for the demo user endpoint (Data layer / external I/O).
@RestApi()
abstract class RestApiClient {
  factory RestApiClient(Dio dio, {String baseUrl}) = _RestApiClient;

  @GET('users/1')
  Future<UserDto> fetchUser();
}
