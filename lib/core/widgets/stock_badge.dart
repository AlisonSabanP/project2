import 'package:flutter/material.dart';

import '../../features/inventory/domain/entities/movement.dart';

/// Colour and label associated with a stock level.
class StockVisuals {
  const StockVisuals({required this.color, required this.label, required this.icon});

  final Color color;
  final String label;
  final IconData icon;
}

/// Central place for the stock colours, so every screen shows the same signal.
abstract final class StockStatus {
  static StockVisuals of(
    BuildContext context, {
    required int currentStock,
    required int minimumStock,
  }) {
    final scheme = Theme.of(context).colorScheme;
    if (currentStock <= 0) {
      return StockVisuals(
        color: scheme.error,
        label: 'Agotado',
        icon: Icons.remove_circle_outline,
      );
    }
    if (currentStock <= minimumStock) {
      return StockVisuals(
        color: scheme.error,
        label: 'Stock bajo',
        icon: Icons.warning_amber_outlined,
      );
    }
    return StockVisuals(
      color: scheme.primary,
      label: 'Disponible',
      icon: Icons.check_circle_outline,
    );
  }

  static IconData movementIcon(MovementType type) {
    switch (type) {
      case MovementType.entry:
        return Icons.arrow_downward;
      case MovementType.exit:
        return Icons.arrow_upward;
      case MovementType.adjustment:
        return Icons.tune;
    }
  }

  static Color movementColor(BuildContext context, MovementType type) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case MovementType.entry:
        return scheme.primary;
      case MovementType.exit:
        return scheme.tertiary;
      case MovementType.adjustment:
        return scheme.secondary;
    }
  }
}

/// Compact coloured chip showing a stock figure.
class StockBadge extends StatelessWidget {
  const StockBadge({
    super.key,
    required this.currentStock,
    required this.minimumStock,
  });

  final int currentStock;
  final int minimumStock;

  @override
  Widget build(BuildContext context) {
    final visuals = StockStatus.of(
      context,
      currentStock: currentStock,
      minimumStock: minimumStock,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: visuals.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visuals.icon, size: 14, color: visuals.color),
          const SizedBox(width: 4),
          Text(
            '$currentStock',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: visuals.color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
