import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import 'package:go_router/go_router.dart';
import 'rx_slist_controller.dart';

/// Demonstrates [RxSList] with basic add/assign/clear and auto-status tracking.
class RxSListPage extends GetView<RxSListController> {
  const RxSListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = controller.list;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RxSList - Basic'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Use RxList APIs directly. Status auto-syncs to\n'
                  'loaded / empty on add / assignAll / clear calls.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.loadData,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Assign Data'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.clear,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status badge
            Obx(
              () => list.on(
                idle: () => _StatusBadge(
                  label: 'Idle',
                  color: Colors.blueGrey,
                ),
                loading: () => _StatusBadge(
                  label: 'Initial (loading)',
                  color: Colors.orange,
                ),
                loaded: (data) => _StatusBadge(
                  label: 'Loaded (${data.length} items)',
                  color: Colors.green,
                ),
                empty: () => _StatusBadge(label: 'Empty', color: Colors.grey),
                error: (msg) =>
                    _StatusBadge(label: 'Error: $msg', color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),

            // List content
            Expanded(
              child: Obx(
                () => list.on(
                  idle: () => const Center(
                    child: Text('Idle state. Tap "Assign Data" to load.'),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (data) => ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(data[i]),
                    ),
                  ),
                  empty: () => const Center(
                    child: Text('No items. Tap "Assign Data" to start.'),
                  ),
                  error: (msg) => Center(child: Text('Error: $msg')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
