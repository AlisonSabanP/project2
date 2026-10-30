import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/formatters.dart';
import '../../../../core/widgets/stock_badge.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../inventory/presentation/widgets/movement_tile.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../products/presentation/screens/product_detail_screen.dart';
import '../../../products/presentation/screens/product_form_screen.dart';
import '../../../reports/domain/entities/inventory_summary.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../scanner/presentation/screens/scanner_screen.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import 'history_screen.dart';

/// Home dashboard: catalogue figures, low stock alerts and shortcuts.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(inventorySummaryProvider);
    final alertsAsync = ref.watch(stockAlertsListProvider);
    final recentMovements = ref.watch(movementHistoryProvider);
    final profile = ref.watch(localProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de bodega'),
        actions: [
          IconButton(
            tooltip: 'Escanear',
            onPressed: () => _openScanner(context),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventorySummaryProvider);
          ref.invalidate(stockAlertsListProvider);
          ref.invalidate(productListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            profile.maybeWhen(
              data: (value) => Text(
                value.isEmpty
                    ? 'Configure el responsable en Perfil'
                    : 'Responsable: ${value.responsibleName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(describeFailure(error)),
              data: (summary) => _SummaryGrid(summary: summary),
            ),
            const SizedBox(height: 20),
            Text(
              'Alertas de stock',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            alertsAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(describeFailure(error)),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Sin alertas de stock'),
                      subtitle: Text(
                        'Ningun producto esta en o por debajo de su minimo.',
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final alert in alerts.take(6))
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProductDetailScreen(
                                productId: alert.product.id!,
                              ),
                            ),
                          ),
                          title: Text(alert.product.name),
                          subtitle: Text(
                            'Minimo ${alert.product.minimumStock} | '
                            'faltan ${alert.missingUnits} para el minimo',
                          ),
                          trailing: StockBadge(
                            currentStock: alert.product.currentStock,
                            minimumStock: alert.product.minimumStock,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Accesos rapidos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ShortcutGrid(
              onNewProduct: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProductFormScreen(),
                ),
              ),
              onScan: () => _openScanner(context),
              onHistory: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ultimos movimientos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            recentMovements.when(
              skipLoadingOnRefresh: true,
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(describeFailure(error)),
              data: (movements) {
                if (movements.isEmpty) {
                  return const Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      title: Text('Sin movimientos registrados'),
                      subtitle: Text(
                        'Las entradas, salidas y ajustes apareceran aqui.',
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final movement in movements.take(5))
                      MovementTile(movement: movement),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScannerScreen()),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final InventorySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Productos activos',
                value: '${summary.activeProductCount}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Unidades en stock',
                value: '${summary.totalUnits}',
                icon: Icons.numbers,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Valor de compra',
                value: Formatters.money(summary.purchaseValue),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Alertas',
                value: '${summary.lowStockCount}',
                icon: Icons.warning_amber_outlined,
                highlight: summary.lowStockCount > 0
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: highlight ?? theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight,
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({
    required this.onNewProduct,
    required this.onScan,
    required this.onHistory,
  });

  final VoidCallback onNewProduct;
  final VoidCallback onScan;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Shortcut(
            icon: Icons.add_box_outlined,
            label: 'Nuevo producto',
            onTap: onNewProduct,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Shortcut(
            icon: Icons.qr_code_scanner,
            label: 'Escanear',
            onTap: onScan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Shortcut(
            icon: Icons.history,
            label: 'Historial',
            onTap: onHistory,
          ),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
