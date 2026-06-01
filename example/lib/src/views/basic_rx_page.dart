import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import 'package:go_router/go_router.dart';
import 'basic_rx_controller.dart';

class BasicRxPage extends GetView<BasicRxController> {
  const BasicRxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Obx(() => Text('basic_rx_appbar_title'.tr)),
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
              children: [
                // 1. Point Counter Card
                _buildCounterCard(controller, theme, isDark, primaryColor),
                const SizedBox(height: 20),

                // 2. Debounced Search Card
                _buildSearchCard(controller, theme, isDark, primaryColor),
                const SizedBox(height: 20),

                // 3. RxList Items Card (Practice card for adding/removing items)
                _buildRxListCard(controller, theme, isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterCard(BasicRxController controller, ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                'basic_rx_counter_title'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Obx(() => Text(
                  'basic_rx_obx_badge'.tr,
                  style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                )),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            return Text(
              '${controller.count.value}',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: controller.increment,
              icon: const Icon(Icons.add_rounded),
              label: Obx(() => Text(
                'basic_rx_increment_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchCard(BasicRxController controller, ThemeData theme, bool isDark, Color primaryColor) {
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
          Obx(() => TextField(
            onChanged: (val) => controller.searchQuery.value = val,
            decoration: InputDecoration(
              hintText: 'basic_rx_search_hint'.tr,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                'basic_rx_status_label'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              )),
              Obx(() {
                final status = controller.searchStatus.value;
                Color statusColor = Colors.grey;
                if (status == 'Searching...') statusColor = Colors.orangeAccent;
                if (status == 'Success') statusColor = Colors.green;

                String localizedStatus = 'basic_rx_status_idle'.tr;
                if (status == 'Searching...') localizedStatus = 'basic_rx_status_searching'.tr;
                if (status == 'Success') localizedStatus = 'basic_rx_status_success'.tr;

                return Text(
                  localizedStatus,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final result = controller.searchResult.value;
            if (result.isEmpty) return const SizedBox();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRxListCard(BasicRxController controller, ThemeData theme, bool isDark, Color primaryColor) {
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
            'basic_rx_list_title'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          )),
          const SizedBox(height: 16),
          
          // Area to display the item list
          Obx(() {
            final items = controller.rxListItems;
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() => Text(
                  'basic_rx_list_empty'.tr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                )),
              );
            }
            
            return Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 8, color: Colors.white10),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          items[index],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          onPressed: () => controller.removeRxItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Add Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: primaryColor,
              ),
              onPressed: controller.addRxItem,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Obx(() => Text(
                'basic_rx_list_add_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
