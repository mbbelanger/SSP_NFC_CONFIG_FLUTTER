import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../scan/scan_provider.dart';
import '../scan/scan_state.dart';

class SessionSummaryScreen extends ConsumerWidget {
  final String locationId;
  final String locationName;

  const SessionSummaryScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanStateProvider);
    final sessionHistory = scanState.sessionHistory;

    final successCount = sessionHistory.where((e) => e.success).length;
    final failCount = sessionHistory.where((e) => !e.success).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/scan/$locationId?name=${Uri.encodeComponent(locationName)}'),
        ),
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              children: [
                Text(
                  'Session Complete',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      label: 'Total',
                      value: sessionHistory.length.toString(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _StatItem(
                      label: 'Success',
                      value: successCount.toString(),
                      color: Colors.green,
                    ),
                    _StatItem(
                      label: 'Failed',
                      value: failCount.toString(),
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: sessionHistory.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessionHistory.length,
                    itemBuilder: (context, index) {
                      // Show most recent first
                      final entry = sessionHistory[sessionHistory.length - 1 - index];
                      return _HistoryCard(entry: entry);
                    },
                  ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(scanStateProvider.notifier).resetForNextTag();
                      context.go('/scan/$locationId?name=${Uri.encodeComponent(locationName)}');
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear & Continue'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/scan/$locationId?name=${Uri.encodeComponent(locationName)}'),
                    icon: const Icon(Icons.nfc),
                    label: const Text('Continue Scanning'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SessionHistoryEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.success
              ? Colors.green.withOpacity(0.1)
              : Theme.of(context).colorScheme.error.withOpacity(0.1),
          child: Icon(
            entry.success ? Icons.check : Icons.close,
            color: entry.success
                ? Colors.green
                : Theme.of(context).colorScheme.error,
          ),
        ),
        title: Text(
          entry.tableName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UID: ${entry.nfcUid}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            Text(
              _formatTime(entry.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (!entry.success && entry.errorMessage != null)
              Text(
                entry.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tags provisioned yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning to see your progress',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
