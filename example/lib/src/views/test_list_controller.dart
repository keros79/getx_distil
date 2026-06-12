import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import '../config/app_config.dart';

class TestListController extends GetxController {
  late final AppConfig _appConfig;

  @override
  void onInit() {
    super.onInit();
    _appConfig = Get.find<AppConfig>();
  }

  // ── Locale ──────────────────────────────────────────────
  bool get isKorean => (Get.locale?.languageCode ?? 'ko') == 'ko';

  void toggleLocale() {
    Get.locale =
        isKorean ? const Locale('en', 'US') : const Locale('ko', 'KR');
  }

  // ── Theme ────────────────────────────────────────────────
  bool get isDarkMode => _appConfig.isDarkMode.value;
  Rx<bool> get isDarkModeRx => _appConfig.isDarkMode;

  void toggleTheme() => _appConfig.isDarkMode.toggle();
}
