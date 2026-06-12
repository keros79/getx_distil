import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import 'package:go_router/go_router.dart';
import 'rx_slist_paging_controller.dart';

/// Demonstrates [RxSList] paging pattern using [addAll] + [hasMore].
class RxSListPagingPage extends GetView<RxSListPagingController> {
  const RxSListPagingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = controller.pagedList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RxSList - Paging'),
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
                  'First page uses assignAll. Subsequent pages use addAll.\n'
                  'hasMore = false indicates all pages are loaded.',
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
                    onPressed: controller.loadFirstPage,
                    icon: const Icon(Icons.first_page, size: 18),
                    label: const Text('First Page'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (list.hasMore) {
                        controller.loadNextPage();
                      }
                    },
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: const Text('Next Page'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.simulatePagingError,
                    icon: const Icon(Icons.error_outline, size: 18),
                    label: const Text('Sim Error'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reset button + page info
            Row(
              children: [
                TextButton.icon(
                  onPressed: controller.resetPagedList,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                ),
                const Spacer(),
                Obx(
                  () => list.on(
                    idle: () => const Chip(
                      avatar: Icon(Icons.pause, size: 16),
                      label: Text('Idle'),
                    ),
                    loading: () => const Chip(
                      avatar: Icon(Icons.hourglass_empty, size: 16),
                      label: Text('Loading'),
                    ),
                    loaded: (data) => Chip(
                      avatar: Icon(
                        list.hasMore ? Icons.unfold_more : Icons.check_circle,
                        size: 16,
                        color: list.hasMore ? Colors.orange : Colors.green,
                      ),
                      label: Text(
                        list.hasMore
                            ? '${data.length} items · More available'
                            : '${data.length} items · All loaded',
                      ),
                    ),
                    empty: () => const Chip(label: Text('Empty')),
                    error: (msg) => Chip(
                      avatar: const Icon(
                        Icons.error,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: Text(msg),
                      backgroundColor: Colors.red.shade50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List content
            Expanded(
              child: Obx(
                () => list.on(
                  idle: () => const Center(
                    child: Text('Idle. Tap "First Page" to begin.'),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (data) => ListView.separated(
                    itemCount: data.length + (list.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      if (i == data.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Obx(() {
                              if (controller.isNextPageLoading.value) {
                                return const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                );
                              }
                              return FilledButton.tonalIcon(
                                onPressed: controller.loadNextPage,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Load More'),
                              );
                            }),
                          ),
                        );
                      }
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.tertiaryContainer,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                        title: Text(data[i]),
                      );
                    },
                  ),
                  empty: () => const Center(
                    child: Text('No data. Tap "First Page" to begin.'),
                  ),
                  error: (msg) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(msg, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Existing data is preserved.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: controller.resetPagedList,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
