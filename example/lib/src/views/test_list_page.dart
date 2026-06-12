import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import 'package:go_router/go_router.dart';
import 'test_list_controller.dart';

class TestListPage extends GetView<TestListController> {
  const TestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'test_list_title'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Localization toggle
          IconButton(
            icon: Text(
              controller.isKorean ? '🇰🇷' : '🇺🇸',
              style: const TextStyle(fontSize: 20),
            ),
            tooltip: 'Toggle Language',
            onPressed: controller.toggleLocale,
          ),
          // Theme toggle — isDarkMode는 별도 Rx이므로 Obx 유지
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isDarkModeRx.value
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              tooltip: 'Toggle Theme',
              onPressed: controller.toggleTheme,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Basic Rx & Actions
                _buildMenuCard(
                  context,
                  title: 'test_list_basic_rx_title'.tr,
                  subtitle: 'test_list_basic_rx_desc'.tr,
                  route: '/basic-rx',
                  borderColor: Colors.amberAccent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),

                // 2. Scoped DI Stack
                _buildMenuCard(
                  context,
                  title: 'test_list_scoped_di_title'.tr,
                  subtitle: 'test_list_scoped_di_desc'.tr,
                  route: '/nested-scope',
                  borderColor: Colors.purpleAccent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),

                // 3. Engine Safety Guard
                _buildMenuCard(
                  context,
                  title: 'test_list_safety_title'.tr,
                  subtitle: 'test_list_safety_desc'.tr,
                  route: '/safety',
                  borderColor: Colors.greenAccent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),

                // 4. Pipeline & Performance
                _buildMenuCard(
                  context,
                  title: 'test_list_pipeline_title'.tr,
                  subtitle: 'test_list_pipeline_desc'.tr,
                  route: '/concurrent',
                  borderColor: Colors.cyanAccent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),

                // 5. RxSList Demo
                _buildMenuCard(
                  context,
                  title: '6. RxSList Basic',
                  subtitle: 'RxSList with auto-status tracking via RxList APIs',
                  route: '/rx-slist',
                  borderColor: Colors.indigoAccent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),

                // 6. RxSList Paging Demo
                _buildMenuCard(
                  context,
                  title: '7. RxSList Paging',
                  subtitle: 'Infinite-scroll paging with addAll + hasMore',
                  route: '/rx-slist-paging',
                  borderColor: Colors.tealAccent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),

                // 7. RxS Demo
                _buildMenuCard(
                  context,
                  title: '8. RxS Single Value Status',
                  subtitle:
                      'RxS with loading/loaded/error auto-status tracking',
                  route: '/rx-s',
                  borderColor: Colors.deepOrangeAccent.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),

                // 8. Extra Settings
                _buildMenuCard(
                  context,
                  title: 'test_list_settings_card_title'.tr,
                  subtitle: 'test_list_settings_card_desc'.tr,
                  route: '/settings',
                  borderColor: Colors.pinkAccent.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String route,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x1A000000) : const Color(0x06000000),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
