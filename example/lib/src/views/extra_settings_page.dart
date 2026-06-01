import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';

class ExtraSettingsPage extends StatelessWidget {
  const ExtraSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final config = Get.find<AppConfig>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        // Obx integration to immediately reflect localization changes
        title: Obx(() => Text(
          'extra_settings_title'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Visual Theme Customizer
                _buildThemeCard(theme, isDark, primaryColor, config),
                const SizedBox(height: 20),

                // 2. Localization Settings
                _buildLanguageCard(theme, isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(ThemeData theme, bool isDark, Color primaryColor, AppConfig config) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
            'settings_theme_title'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          )),
          const SizedBox(height: 16),
          Obx(() {
            final darkActive = config.isDarkMode.value;
            return SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.purpleAccent,
              title: Row(
                children: [
                  Icon(
                    darkActive ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: darkActive ? Colors.purpleAccent : Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  Obx(() => Text(
                    darkActive ? 'settings_dark_active'.tr : 'settings_light_active'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  )),
                ],
              ),
              value: darkActive,
              onChanged: (val) => config.isDarkMode.toggle(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(ThemeData theme, bool isDark, Color primaryColor) {
    return Obx(() {
      final currentLanguageCode = Get.locale?.languageCode ?? 'ko';

      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
              'settings_language_title'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                // English Button
                Expanded(
                  child: InkWell(
                    onTap: () => Get.locale = const Locale('en', 'US'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: currentLanguageCode == 'en'
                            ? Colors.purple.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentLanguageCode == 'en'
                              ? Colors.purpleAccent
                              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                          width: currentLanguageCode == 'en' ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 8),
                          Text(
                            'English',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: currentLanguageCode == 'en' ? Colors.purpleAccent : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Korean Button
                Expanded(
                  child: InkWell(
                    onTap: () => Get.locale = const Locale('ko', 'KR'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: currentLanguageCode == 'ko'
                            ? Colors.purple.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentLanguageCode == 'ko'
                              ? Colors.purpleAccent
                              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                          width: currentLanguageCode == 'ko' ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🇰🇷', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 8),
                          Text(
                            '한국어',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: currentLanguageCode == 'ko' ? Colors.purpleAccent : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
