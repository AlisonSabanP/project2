import 'package:flutter/material.dart';

import '../../../../core/formatting/formatters.dart';
import '../../../../core/widgets/stock_badge.dart';
import '../../domain/entities/movement.dart';

/// Ledger row used by the product detail and the history screens.
class MovementTile extends StatelessWidget {
  const MovementTile({
    super.key,
    required this.movement,
    this.productLabel,
  });

  final Movement movement;

  /// Product name and code, shown when the list mixes several products.
  final String? productLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = StockStatus.movementColor(context, movement.type);
    final sign = movement.delta >= 0 ? '+' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(
                StockStatus.movementIcon(movement.type),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          productLabel ?? _typeLabel(movement.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '$sign${movement.delta}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (productLabel != null)
                    Text(
                      _typeLabel(movement.type),
                      style: theme.textTheme.bodySmall,
                    ),
                  Text(
                    movement.type == MovementType.adjustment
                        ? 'Contado ${movement.quantity} | antes ${movement.previousStock}'
                        : 'Cantidad ${movement.quantity} | antes ${movement.previousStock} | queda ${movement.resultingStock}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    movement.reason,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.dateTime(movement.dateTime)}  |  ${movement.responsible}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(MovementType type) {
    switch (type) {
      case MovementType.entry:
        return 'Entrada';
      case MovementType.exit:
        return 'Salida';
      case MovementType.adjustment:
        return 'Ajuste';
    }
  }
}
