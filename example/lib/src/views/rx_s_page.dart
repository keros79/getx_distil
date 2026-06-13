import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';
import 'package:go_router/go_router.dart';
import 'rx_s_controller.dart';

/// Demonstrates [RxS] with loading/loaded/error auto-status tracking.
class RxSPage extends GetView<RxSController> {
  const RxSPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = controller.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RxS - Single Value Status'),
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
                  'RxS<T> = Rxn<T> + loading/loaded/error status.\n'
                  'Value setter/update → auto loaded.\n'
                  'Error is sticky — must be set manually.',
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
                    onPressed: controller.loadUser,
                    icon: const Icon(Icons.person, size: 18),
                    label: const Text('Load User'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.updateName,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Update Name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.setNull,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Set Null'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.simulateError,
                    icon: const Icon(Icons.error_outline, size: 18),
                    label: const Text('Sim Error'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: controller.reset,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
            ),
            const SizedBox(height: 12),

            // Status badge + user card
            Expanded(
              child: Obx(
                () => user.on(
                  idle: () => _buildStatusMessage(
                    context,
                    icon: Icons.pause_circle_outline,
                    label: 'Idle',
                    color: Colors.blueGrey,
                    child: const Text(
                      'Tap "Load User" to start.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  loading: () => _buildStatusMessage(
                    context,
                    icon: Icons.hourglass_empty,
                    label: 'Initial (loading)',
                    color: Colors.orange,
                    child: const CircularProgressIndicator(),
                  ),
                  loaded: (data) {
                    if (data == null) {
                      return _buildStatusMessage(
                        context,
                        icon: Icons.person_off,
                        label: 'Loaded (null)',
                        color: Colors.grey,
                        child: const Text(
                          'User is null.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }
                    return _buildUserCard(context, data);
                  },
                  error: (msg) => _buildStatusMessage(
                    context,
                    icon: Icons.error,
                    label: 'Error',
                    color: Colors.red,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg ?? 'Unknown error',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: controller.reset,
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

  Widget _buildStatusMessage(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Widget child,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
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
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.name.isNotEmpty ? user.name[0] : '?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
