import 'package:flutter/widgets.dart';
import 'package:getx_distil/get.dart';
import '../config/app_config.dart';

class SettingsController extends GetxController {
  bool get isDarkMode => AppConfig.isDarkMode.value;

  String get currentLanguage => Get.locale?.languageCode ?? 'en';

  void toggleTheme() {
    AppConfig.isDarkMode.toggle();
  }

  void changeLanguage(String langCode) {
    if (langCode == 'ko') {
      Get.locale = const Locale('ko', 'KR');
    } else {
      Get.locale = const Locale('en', 'US');
    }
  }
}
