import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';

import 'core/config/app_config.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/app_translations.dart';
import 'models/domain/user_repository.dart';
import 'services/rest_api_client.dart';
import 'services/user_repository_impl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // App-lifetime objects only. Screen scopes live in core/routes/app_router.dart.
    return GetMaterialApp(
      routerConfig: appRouter,
      bindings: [
        Bind<AppConfig>(() => AppConfig()),
        Bind<Dio>(() => createDio()),
        Bind<RestApiClient>(() => RestApiClient(Get.find<Dio>())),
        Bind<UserRepository>(
          () => UserRepositoryImpl(client: Get.find<RestApiClient>()),
        ),
      ],
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      translations: AppTranslations(),
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
