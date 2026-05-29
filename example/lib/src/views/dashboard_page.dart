import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:getx_distil/get.dart';
import 'dashboard_controller.dart';
import '../config/app_config.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

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
          'dashboard_title'.tr,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: themeColor,
            ),
            onPressed: () => AppConfig.isDarkMode.toggle(),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'welcome_msg'.tr,
              style: TextStyle(
                color: isDark ? const Color(0xB2FFFFFF) : const Color(0xB2000000),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'app_subtitle'.tr,
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // Real-Time pricing card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0x2600E5FF) : const Color(0x14448AFF),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'price_feed'.tr,
                        style: TextStyle(
                          color: isDark ? const Color(0x99FFFFFF) : const Color(0x99000000),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Status trend chip - Wrapped in a precise Obx widget!
                      Obx(() {
                        final statusVal = controller.status.value;
                        final isBull = statusVal == 'Bullish';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isBull
                                ? const Color(0x334CAF50)
                                : const Color(0x33FF5252),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            statusVal.tr,
                            style: TextStyle(
                              color: isBull ? Colors.green : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // High frequency pricing tick - Wrapped in a precise Obx widget!
                  Obx(() {
                    final statusVal = controller.status.value;
                    final isBull = statusVal == 'Bullish';
                    return Text(
                      '\$${controller.price.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isBull ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                            color: isBull ? const Color(0x6669F0AE) : const Color(0x66FF5252),
                            blurRadius: 15,
                          )
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    'high_freq_desc'.tr,
                    style: TextStyle(
                      color: isDark ? const Color(0x66FFFFFF) : const Color(0x66000000),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Interactive clicks card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0x1A000000) : const Color(0x08000000),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
                border: theme.cardTheme.shape is RoundedRectangleBorder
                    ? (theme.cardTheme.shape as RoundedRectangleBorder).side != BorderSide.none
                        ? Border.all(
                            color: ((theme.cardTheme.shape as RoundedRectangleBorder).side).color,
                          )
                        : Border.all(color: isDark ? Colors.white10 : Colors.black12)
                    : Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                children: [
                  Text(
                    'counter_title'.tr,
                    style: TextStyle(
                      color: isDark ? const Color(0x99FFFFFF) : const Color(0x99000000),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Counter value metric - Wrapped in a precise Obx widget!
                  Obx(() {
                    return Text(
                      'click_metric'.trArgs([controller.counter.value.toString()]),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: controller.increment,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      'btn_increment'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
