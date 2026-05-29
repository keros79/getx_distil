import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:getx_distil/get.dart';
import 'settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'settings_title'.tr,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'pref_section'.tr,
              style: TextStyle(
                color: themeColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Theme configuration card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: theme.cardTheme.shape is RoundedRectangleBorder
                    ? (theme.cardTheme.shape as RoundedRectangleBorder).side != BorderSide.none
                        ? Border.all(
                            color: ((theme.cardTheme.shape as RoundedRectangleBorder).side).color,
                          )
                        : Border.all(color: isDark ? Colors.white10 : Colors.black12)
                    : Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              // Wrapped in a precise Obx widget!
              child: Obx(() {
                final activeDark = controller.isDarkMode;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          activeDark ? Icons.dark_mode : Icons.light_mode,
                          color: themeColor,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'theme_mode'.tr,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              activeDark ? 'dark_desc'.tr : 'light_desc'.tr,
                              style: TextStyle(
                                color: isDark ? const Color(0x80FFFFFF) : const Color(0x80000000),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      activeThumbColor: themeColor,
                      activeTrackColor: activeDark ? const Color(0x8000E5FF) : const Color(0x80448AFF),
                      value: activeDark,
                      onChanged: (val) => controller.toggleTheme(),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 20),

            // Language configuration card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: theme.cardTheme.shape is RoundedRectangleBorder
                    ? (theme.cardTheme.shape as RoundedRectangleBorder).side != BorderSide.none
                        ? Border.all(
                            color: ((theme.cardTheme.shape as RoundedRectangleBorder).side).color,
                          )
                        : Border.all(color: isDark ? Colors.white10 : Colors.black12)
                    : Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: themeColor),
                      const SizedBox(width: 16),
                      Text(
                        'language_sel'.tr,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // List of language rows - Wrapped in a precise Obx widget!
                  Obx(() {
                    final currentLang = controller.currentLanguage;
                    return Column(
                      children: [
                        _buildLanguageRow(
                          title: 'English (US)',
                          langCode: 'en',
                          isSelected: currentLang == 'en',
                          themeColor: themeColor,
                          textColor: textColor,
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildLanguageRow(
                          title: '한국어 (KR)',
                          langCode: 'ko',
                          isSelected: currentLang == 'ko',
                          themeColor: themeColor,
                          textColor: textColor,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow({
    required String title,
    required String langCode,
    required bool isSelected,
    required Color themeColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: () => controller.changeLanguage(langCode),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: themeColor)
            else
              Icon(
                Icons.circle_outlined,
                color: controller.isDarkMode ? const Color(0x4DFFFFFF) : const Color(0x4D000000),
              ),
          ],
        ),
      ),
    );
  }
}
