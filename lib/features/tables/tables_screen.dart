import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/graphql_client.dart';
import '../../models/table.dart';
import '../scan/scan_provider.dart';

class TablesScreen extends ConsumerStatefulWidget {
  final String locationId;
  final String locationName;

  const TablesScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  String _searchQuery = '';
  TableFilter _filter = TableFilter.all;

  Future<bool> _showDeleteConfirmation(BuildContext context, SSPTable table) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove NFC Tag'),
        content: Text(
          'Are you sure you want to remove the NFC tag from ${table.name}?\n\n'
          'This will deactivate the tag and allow you to assign a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _deleteNfcTag(SSPTable table) async {
    if (table.nfcTag == null) return;
    try {
      final client = ref.read(graphqlRawClientProvider);
      final result = await deleteNfcTag(client, table.nfcTag!.id);
      if (result) {
        ref.invalidate(tablesProvider(widget.locationId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete NFC tag: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider(widget.locationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locationName.isNotEmpty ? widget.locationName : 'All Tables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(tablesProvider(widget.locationId)),
          ),
        ],
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tablesProvider(widget.locationId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tables) => _buildContent(tables),
      ),
    );
  }

  Widget _buildContent(List<SSPTable> tables) {
    final filteredTables = _getFilteredTables(tables);

    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search tables...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == TableFilter.all,
                      onSelected: () => setState(() => _filter = TableFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'With NFC',
                      selected: _filter == TableFilter.withNfc,
                      onSelected: () => setState(() => _filter = TableFilter.withNfc),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'No NFC',
                      selected: _filter == TableFilter.noNfc,
                      onSelected: () => setState(() => _filter = TableFilter.noNfc),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Damaged',
                      selected: _filter == TableFilter.damaged,
                      onSelected: () => setState(() => _filter = TableFilter.damaged),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _StatsRow(tables: tables),
        ),
        const SizedBox(height: 16),

        // Table List
        Expanded(
          child: filteredTables.isEmpty
              ? _EmptyState(filter: _filter)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTables.length,
                  itemBuilder: (context, index) {
                    final table = filteredTables[index];
                    if (table.hasActiveNfc) {
                      return Dismissible(
                        key: Key('table_${table.id}_${table.nfcTag?.id ?? "no_tag"}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.white),
                              SizedBox(height: 4),
                              Text(
                                'Remove Tag',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          // Show confirmation dialog
                          final confirmed = await _showDeleteConfirmation(context, table);
                          if (confirmed) {
                            // Perform the delete - this will refresh the list
                            await _deleteNfcTag(table);
                          }
                          // Always return false - the list refresh will handle removing the item
                          // This prevents the "dismissed Dismissible still in tree" error
                          return false;
                        },
                        child: _TableCard(table: table),
                      );
                    }
                    return _TableCard(table: table);
                  },
                ),
        ),
      ],
    );
  }

  List<SSPTable> _getFilteredTables(List<SSPTable> tables) {
    var filtered = tables;

    // Apply filter
    switch (_filter) {
      case TableFilter.all:
        break;
      case TableFilter.withNfc:
        filtered = filtered.where((t) => t.hasActiveNfc).toList();
        break;
      case TableFilter.noNfc:
        filtered = filtered.where((t) => t.hasNoNfc).toList();
        break;
      case TableFilter.damaged:
        filtered = filtered.where((t) => t.hasDamagedNfc).toList();
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }
}

enum TableFilter { all, withNfc, noNfc, damaged }

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<SSPTable> tables;

  const _StatsRow({required this.tables});

  @override
  Widget build(BuildContext context) {
    final withNfc = tables.where((t) => t.hasActiveNfc).length;
    final noNfc = tables.where((t) => t.hasNoNfc).length;
    final damaged = tables.where((t) => t.hasDamagedNfc).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: tables.length.toString(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'With NFC',
            value: withNfc.toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'No NFC',
            value: noNfc.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Damaged',
            value: damaged.toString(),
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final SSPTable table;

  const _TableCard({required this.table});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildNfcIcon(context),
        title: Text(
          table.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          '${table.numberOfSeats} seats • ${table.status.displayName}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: table.activeNfcTag != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'UID: ${_formatUid(table.activeNfcTag!.uid)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildNfcIcon(BuildContext context) {
    if (table.hasActiveNfc) {
      return CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: const Icon(Icons.signal_cellular_alt, color: Colors.green),
      );
    }

    if (table.hasDamagedNfc) {
      return CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
        child: Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.orange.withOpacity(0.1),
      child: const Icon(Icons.signal_cellular_off, color: Colors.orange),
    );
  }

  String _formatUid(String uid) {
    if (uid.length <= 8) return uid;
    return '${uid.substring(0, 4)}...${uid.substring(uid.length - 4)}';
  }
}

class _EmptyState extends StatelessWidget {
  final TableFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    String message;
    switch (filter) {
      case TableFilter.all:
        message = 'No tables found';
        break;
      case TableFilter.withNfc:
        message = 'No tables with active NFC tags';
        break;
      case TableFilter.noNfc:
        message = 'All tables have NFC tags!';
        break;
      case TableFilter.damaged:
        message = 'No tables with damaged NFC tags';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
