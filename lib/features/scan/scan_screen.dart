import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/graphql_client.dart';
import '../../models/table.dart';
import 'scan_provider.dart';
import 'scan_state.dart';
import 'widgets/nfc_pulse_animation.dart';
import 'widgets/table_selector.dart';

class ScanScreen extends ConsumerWidget {
  final String locationId;
  final String locationName;

  const ScanScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanStateProvider);
    final tablesAsync = ref.watch(tablesProvider(locationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(locationName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _buildBody(context, ref, scanState, tablesAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ScanState scanState,
    AsyncValue<List<SSPTable>> tablesAsync,
  ) {
    switch (scanState.status) {
      case ScanStatus.initial:
      case ScanStatus.ready:
        return _ReadyToScanView(
          sessionCount: scanState.sessionHistory.length,
          locationId: locationId,
        );

      case ScanStatus.tagDetected:
        return tablesAsync.when(
          data: (tables) => _TagDetectedView(
            uid: scanState.detectedUid!,
            tables: tables,
            selectedTableId: scanState.selectedTableId,
            writeUrlEnabled: scanState.writeUrlEnabled,
            onTableSelected: (tableId) {
              ref.read(scanStateProvider.notifier).selectTable(tableId);
            },
            onWriteUrlToggled: (enabled) {
              ref.read(scanStateProvider.notifier).toggleWriteUrl(enabled);
            },
            onRegister: () {
              if (scanState.selectedTableId != null) {
                final selectedTable = tables.firstWhere(
                  (t) => t.id == scanState.selectedTableId,
                );
                ref.read(scanStateProvider.notifier).registerTag(
                      tableId: scanState.selectedTableId!,
                      tableName: selectedTable.name,
                    );
              }
            },
            onCancel: () {
              ref.read(scanStateProvider.notifier).resetForNextTag();
            },
            onDeleteNfcTag: (table) async {
              if (table.nfcTag == null) return false;
              try {
                final client = ref.read(graphqlRawClientProvider);
                final result = await deleteNfcTag(client, table.nfcTag!.id);
                if (result) {
                  ref.invalidate(tablesProvider(locationId));
                  return true;
                }
                return false;
              } catch (e) {
                return false;
              }
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error loading tables: $error'),
          ),
        );

      case ScanStatus.registering:
        return _LoadingView(
          message: 'Registering tag...',
          subtitle: 'Table ${scanState.selectedTableId}',
        );

      case ScanStatus.writing:
        return _LoadingView(
          message: 'Writing URL to tag...',
          subtitle: 'Keep phone on tag',
          showProgress: true,
        );

      case ScanStatus.success:
        return _SuccessView(
          tag: scanState.registeredTag!,
          onScanNext: () {
            ref.invalidate(tablesProvider(locationId));
            ref.read(scanStateProvider.notifier).resetForNextTag();
          },
          onViewTables: () {
            ref.invalidate(tablesProvider(locationId));
            context.push('/tables/$locationId?name=${Uri.encodeComponent(locationName)}');
          },
        );

      case ScanStatus.error:
        return _ErrorView(
          message: scanState.errorMessage ?? 'An error occurred',
          onRetry: () {
            ref.read(scanStateProvider.notifier).resetForNextTag();
          },
          onCancel: () => context.pop(),
        );
    }
  }
}

class _ReadyToScanView extends StatelessWidget {
  final int sessionCount;
  final String locationId;

  const _ReadyToScanView({
    required this.sessionCount,
    required this.locationId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const NFCPulseAnimation(),
          const SizedBox(height: 32),
          Text(
            'Ready to scan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap NFC tag to back of phone',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'This session: $sessionCount tags registered',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.push('/tables/$locationId');
              },
              child: const Text('View All Tables'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagDetectedView extends StatelessWidget {
  final String uid;
  final List<SSPTable> tables;
  final String? selectedTableId;
  final bool writeUrlEnabled;
  final ValueChanged<String> onTableSelected;
  final ValueChanged<bool> onWriteUrlToggled;
  final VoidCallback onRegister;
  final VoidCallback onCancel;
  final Future<bool> Function(SSPTable table)? onDeleteNfcTag;

  const _TagDetectedView({
    required this.uid,
    required this.tables,
    required this.selectedTableId,
    required this.writeUrlEnabled,
    required this.onTableSelected,
    required this.onWriteUrlToggled,
    required this.onRegister,
    required this.onCancel,
    this.onDeleteNfcTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tag Info Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.nfc,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tag Detected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    Text(
                      'UID: $uid',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Table Selector
        Expanded(
          child: TableSelector(
            tables: tables,
            selectedTableId: selectedTableId,
            onTableSelected: onTableSelected,
            onDeleteNfcTag: onDeleteNfcTag,
          ),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Write URL Toggle
              CheckboxListTile(
                value: writeUrlEnabled,
                onChanged: (value) => onWriteUrlToggled(value ?? true),
                title: const Text('Write URL to tag'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 8),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedTableId != null ? onRegister : null,
                  child: Text(
                    selectedTableId != null
                        ? 'Register to Selected Table'
                        : 'Select a Table',
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Cancel Button
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;
  final String? subtitle;
  final bool showProgress;

  const _LoadingView({
    required this.message,
    this.subtitle,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (showProgress) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: LinearProgressIndicator(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final dynamic tag;
  final VoidCallback onScanNext;
  final VoidCallback onViewTables;

  const _SuccessView({
    required this.tag,
    required this.onScanNext,
    required this.onViewTables,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.check_circle,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Tag Registered!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UID: ${tag.uid}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                  if (tag.writtenUrl != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'URL: ${tag.writtenUrl}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onScanNext();
              },
              child: const Text('Scan Next Tag'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewTables,
                  child: const Text('View Tables'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'Registration Failed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
