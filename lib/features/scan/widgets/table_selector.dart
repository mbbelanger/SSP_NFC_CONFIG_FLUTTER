import 'package:flutter/material.dart';

import '../../../models/table.dart';

class TableSelector extends StatefulWidget {
  final List<SSPTable> tables;
  final String? selectedTableId;
  final ValueChanged<String> onTableSelected;
  final Future<bool> Function(SSPTable table)? onDeleteNfcTag;

  const TableSelector({
    super.key,
    required this.tables,
    required this.selectedTableId,
    required this.onTableSelected,
    this.onDeleteNfcTag,
  });

  @override
  State<TableSelector> createState() => _TableSelectorState();
}

class _TableSelectorState extends State<TableSelector> {
  bool _showOnlyAvailable = false;
  String _searchQuery = '';

  List<SSPTable> get _filteredTables {
    var tables = widget.tables;

    if (_showOnlyAvailable) {
      tables = tables.where((t) => t.hasNoNfc || t.hasDamagedNfc).toList();
    }

    if (_searchQuery.isNotEmpty) {
      tables = tables
          .where((t) =>
              t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return tables;
  }

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filter tables...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('No tag only'),
                selected: _showOnlyAvailable,
                onSelected: (value) {
                  setState(() {
                    _showOnlyAvailable = value;
                  });
                },
              ),
            ],
          ),
        ),

        // Table List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredTables.length,
            itemBuilder: (context, index) {
              final table = _filteredTables[index];
              final isSelected = table.id == widget.selectedTableId;
              final hasNfc = table.hasActiveNfc;

              // Wrap with Dismissible for tables with NFC tags
              if (hasNfc && widget.onDeleteNfcTag != null) {
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
                      await widget.onDeleteNfcTag!(table);
                    }
                    // Always return false - the list refresh will handle removing the item
                    // This prevents the "dismissed Dismissible still in tree" error
                    return false;
                  },
                  child: _TableListItem(
                    table: table,
                    isSelected: isSelected,
                    isDisabled: hasNfc,
                    onTap: null,
                  ),
                );
              }

              return _TableListItem(
                table: table,
                isSelected: isSelected,
                isDisabled: false,
                onTap: () => widget.onTableSelected(table.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TableListItem extends StatelessWidget {
  final SSPTable table;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _TableListItem({
    required this.table,
    required this.isSelected,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : isDisabled
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),

              // Table info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${table.numberOfSeats} seats • ${table.status.displayName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // NFC Status indicator
              _NFCStatusIndicator(table: table),
            ],
          ),
        ),
      ),
    );
  }
}

class _NFCStatusIndicator extends StatelessWidget {
  final SSPTable table;

  const _NFCStatusIndicator({required this.table});

  @override
  Widget build(BuildContext context) {
    if (table.hasActiveNfc) {
      return Tooltip(
        message: 'Has active NFC tag',
        child: Icon(
          Icons.signal_cellular_alt,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (table.hasDamagedNfc) {
      return Tooltip(
        message: 'NFC tag damaged/lost',
        child: Icon(
          Icons.warning_amber,
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }

    return Text(
      '—',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
