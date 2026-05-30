import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';

class AppConfig extends GetxService {
  final isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Synchronize isDarkMode with Get's themeMode reactively
    ever(isDarkMode, (bool isDark) {
      Get.themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Set initial theme mode after the build frame has completed to prevent build phase issues
    Get.themeMode = isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }
}
