import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import '../../core/config/app_config.dart';

/// Settings screen controller.
///
/// The screen is scoped via `BindingWidget`; `AppConfig` stays an
/// app-lifetime singleton (`GetMaterialApp.bindings`) that this controller
/// delegates theme mutations to. Language changes go through [Get.locale].
class ExtraSettingsController extends GetxController {
  late final AppConfig _appConfig;

  @override
  void onInit() {
    super.onInit();
    _appConfig = Get.find<AppConfig>();
  }

  bool get isDarkMode => _appConfig.isDarkMode.value;

  void toggleTheme() => _appConfig.isDarkMode.toggle();

  String? get currentLanguageCode => Get.locale?.languageCode;

  void setLocale(Locale locale) => Get.locale = locale;
}
