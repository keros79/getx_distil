import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import 'package:go_router/go_router.dart';
import 'nested_scope_controller.dart';

class NestedScopePage extends GetView<NestedScopeController> {
  const NestedScopePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        // controller.depth는 Rx이므로 Obx 유지
        title: Obx(() => Text(
          'nested_scope_appbar_title'.trArgs([controller.depth.toString()]),
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Isolated Counter Card with Nav Controls inside
                _buildIsolatedCounter(controller, theme, isDark, primaryColor),
                const SizedBox(height: 20),
                
                // Stack Actions
                _buildNavControls(context, controller, theme, isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIsolatedCounter(NestedScopeController controller, ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // instanceId는 String(non-Rx)이므로 .tr과 함께 Obx 불필요
              Text(
                'nested_scope_id_label'.trParams({'id': controller.instanceId}),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                // controller.depth는 Rx이므로 Obx 유지
                child: Obx(() => Text(
                  'nested_scope_depth_badge'.trArgs([controller.depth.toString()]),
                  style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            return Text(
              '${controller.localCount.value}',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.purpleAccent,
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'nested_scope_isolated_desc'.tr,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: controller.increment,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'nested_scope_increment_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavControls(BuildContext context, NestedScopeController controller, ThemeData theme, bool isDark, Color primaryColor) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.purpleAccent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: Colors.purpleAccent,
            ),
            onPressed: () => context.push('/nested-scope?depth=${controller.depth + 1}'),
            icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
            label: Text(
              'nested_scope_push_btn'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (controller.depth > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close_rounded),
              label: Text(
                'nested_scope_pop_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
