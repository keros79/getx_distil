import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import 'package:go_router/go_router.dart';
import 'concurrent_update_controller.dart';

class ConcurrentUpdatePage extends GetView<ConcurrentUpdateController> {
  const ConcurrentUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Obx(() => Text('concurrent_appbar_title'.tr)),
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
                // 1. FIFO Sequence Simulator Card
                _buildFifoCard(controller, theme, isDark, primaryColor),
                const SizedBox(height: 20),

                // 2. Loop Batch (RxList) Benchmark Card
                _buildBenchmarkCard(controller, theme, isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFifoCard(ConcurrentUpdateController controller, ThemeData theme, bool isDark, Color primaryColor) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                'concurrent_fifo_title'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              )),
              Obx(() {
                final active = controller.isProcessingFifo.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: active ? Colors.cyan.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    active ? 'concurrent_processing'.tr : 'concurrent_idle'.tr,
                    style: TextStyle(
                      color: active ? Colors.cyanAccent : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: controller.triggerSequentialTask,
              icon: const Icon(Icons.touch_app_rounded),
              label: Obx(() => Text(
                'concurrent_spam_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final logs = controller.fifoQueue;
            if (logs.isEmpty) return const SizedBox();
            // Minimally expose only the single most recent completed/in-progress log
            final latestLog = logs.first;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_alt_rounded, color: Colors.cyanAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      latestLog,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBenchmarkCard(ConcurrentUpdateController controller, ThemeData theme, bool isDark, Color primaryColor) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                'concurrent_bench_title'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() => Text(
                  'concurrent_bench_items_badge'.tr,
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: controller.runStandardListBenchmark,
                    child: Obx(() => Text(
                      'concurrent_standard_loop_btn'.tr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    )),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: controller.runRxListBenchmark,
                    child: Obx(() => Text(
                      'concurrent_rx_batch_btn'.tr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    )),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            final tStandard = controller.standardListBuildTime.value;
            final tRx = controller.rxListBuildTime.value;

            final maxVal = (tStandard > tRx ? tStandard : tRx).toDouble();
            final wStandard = maxVal > 0 ? (tStandard / maxVal) : 0.0;
            final wRx = maxVal > 0 ? (tRx / maxVal) : 0.0;

            if (tStandard == 0 && tRx == 0) return const SizedBox();

            return Column(
              children: [
                // Standard Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Text('concurrent_standard_label'.tr, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                        Text('${tStandard}ms', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: wStandard,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // RxList Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Text('concurrent_rx_label'.tr, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                        Text('${tRx}ms', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: wRx,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
