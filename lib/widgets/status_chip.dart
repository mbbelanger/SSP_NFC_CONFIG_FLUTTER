import 'package:flutter/material.dart';

enum StatusType { success, warning, error, info }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _foregroundColor(context)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: _foregroundColor(context),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _backgroundColor(BuildContext context) {
    switch (type) {
      case StatusType.success:
        return Colors.green.withOpacity(0.1);
      case StatusType.warning:
        return Colors.orange.withOpacity(0.1);
      case StatusType.error:
        return Theme.of(context).colorScheme.error.withOpacity(0.1);
      case StatusType.info:
        return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
  }

  Color _foregroundColor(BuildContext context) {
    switch (type) {
      case StatusType.success:
        return Colors.green;
      case StatusType.warning:
        return Colors.orange;
      case StatusType.error:
        return Theme.of(context).colorScheme.error;
      case StatusType.info:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
