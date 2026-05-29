import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:getx_distil/get.dart';
import 'rx_list_bench_controller.dart';

class RxListBenchPage extends GetView<RxListBenchController> {
  const RxListBenchPage({super.key});

  // ─── Design tokens ─────────────────────────────────────────────────────────
  static const _accent = Color(0xFF00E5FF);
  static const _accentGreen = Color(0xFF69F0AE);
  static const _accentAmber = Color(0xFFFFD740);
  static const _surface = Color(0xFF0F172A);
  static const _cardBg = Color(0xFF1E293B);
  static const _cardBorder = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.speed_rounded, color: _accent, size: 22),
            SizedBox(width: 10),
            Text(
              'RxList Benchmark',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white54),
            tooltip: 'Clear All',
            onPressed: controller.clearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopMetricsBar(),
          _buildControlPanel(),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                // Left: live list preview
                Expanded(flex: 5, child: _buildListPreview()),
                const SizedBox(width: 1),
                // Right: run log
                Expanded(flex: 5, child: _buildLogPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top metrics bar ───────────────────────────────────────────────────────

  Widget _buildTopMetricsBar() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _MetricChip(
            label: 'Obx Rebuilds',
            valueBuilder: () => controller.rebuildCount.value.toString(),
            color: _accentAmber,
          ),
          const SizedBox(width: 12),
          _MetricChip(
            label: 'List Items',
            valueBuilder: () => controller.items.length.toString(),
            color: _accent,
          ),
          const SizedBox(width: 12),
          _MetricChip(
            label: 'ever Events',
            valueBuilder: () => controller.workerEventCount.value.toString(),
            color: _accentGreen,
          ),
          const Spacer(),
          Obx(() => controller.isBusy.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 2,
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  // ─── Control panel ─────────────────────────────────────────────────────────

  Widget _buildControlPanel() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batch size selector
          Row(
            children: [
              const Text(
                'Batch size:',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(width: 10),
              Obx(() => Wrap(
                    spacing: 6,
                    children: RxListBenchController.batchSizes.map((n) {
                      final selected = controller.selectedBatch.value == n;
                      return GestureDetector(
                        onTap: () => controller.selectedBatch.value = n,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? _accent.withAlpha(40)
                                : _cardBg,
                            border: Border.all(
                              color: selected ? _accent : _cardBorder,
                              width: selected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$n',
                            style: TextStyle(
                              color:
                                  selected ? _accent : Colors.white54,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          // Action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() {
              final busy = controller.isBusy.value;
              final n = controller.selectedBatch.value;
              return Row(
                children: [
                  _ActionButton(
                    label: 'add() ×$n',
                    icon: Icons.add_circle_outline_rounded,
                    color: _accent,
                    busy: busy,
                    onTap: () => controller.runBatchedAdd(n),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'assignAll() ×$n',
                    icon: Icons.swap_horiz_rounded,
                    color: _accentGreen,
                    busy: busy,
                    onTap: () => controller.runAssignAll(n),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'sort()',
                    icon: Icons.sort_rounded,
                    color: _accentAmber,
                    busy: busy,
                    onTap: controller.runSort,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Live list preview ─────────────────────────────────────────────────────

  Widget _buildListPreview() {
    return Container(
      margin: const EdgeInsets.only(left: 12, bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.list_alt_rounded,
            label: 'Live List Preview',
            trailing: Obx(() => Text(
                  '${controller.items.length} items',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                )),
          ),
          Expanded(
            child: Obx(() {
              // Count this rebuild after the current build pass completes,
              // so we never call setState/markNeedsBuild during a build.
              SchedulerBinding.instance.addPostFrameCallback(
                (_) => controller.notifyRebuild(),
              );
              final list = controller.items;
              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'Run a benchmark to populate the list.',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final hue = (i * 137.5) % 360;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: HSLColor.fromAHSL(
                                    1, hue, 0.7, 0.6)
                                .toColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          list[i],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Log panel ─────────────────────────────────────────────────────────────

  Widget _buildLogPanel() {
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.analytics_rounded,
            label: 'Run Log',
          ),
          Expanded(
            child: Obx(() {
              final logs = controller.logs;
              if (logs.isEmpty) {
                return const Center(
                  child: Text(
                    'Results appear here after each run.',
                    style:
                        TextStyle(color: Colors.white24, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: logs.length,
                separatorBuilder: (context, idx) => const Divider(
                  color: _cardBorder,
                  height: 1,
                ),
                itemBuilder: (_, i) => _LogRow(log: logs[i]),
              );
            }),
          ),
          // Efficiency legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _cardBorder)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 12, color: Colors.white24),
                SizedBox(width: 6),
                Text(
                  'Efficiency = Rebuilds ÷ Mutations  (ideal: ≤ 1/N)',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final String label;
  final String Function() valueBuilder;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.valueBuilder,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Obx(() => Text(
              valueBuilder(),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            )),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedOpacity(
        opacity: busy ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            border: Border.all(color: color.withAlpha(100)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;

  const _PanelHeader({
    required this.icon,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white38),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final BenchLog log;

  const _LogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    // 리빌드 수가 1이면 초록, mutations보다 많으면 빨강
    final rebuildColor = log.rebuilds <= 1
        ? const Color(0xFF69F0AE)
        : log.rebuilds <= log.mutations ~/ 10
            ? const Color(0xFFFFD740)
            : const Color(0xFFFF5252);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  log.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${log.elapsed.inMicroseconds} µs',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _StatBadge(
                  label: 'mutations',
                  value: '${log.mutations}',
                  color: const Color(0xFF00E5FF)),
              const SizedBox(width: 6),
              _StatBadge(
                  label: 'rebuilds',
                  value: '${log.rebuilds}',
                  color: rebuildColor),
              const SizedBox(width: 6),
              _StatBadge(
                label: 'ratio',
                value: log.mutations > 1
                    ? '1/${log.mutations}'
                    : '1/1',
                color: Colors.white24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                color: color.withAlpha(160),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
