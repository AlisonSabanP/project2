import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/domain_exception.dart';
import '../../../../core/formatting/formatters.dart';
import '../../../inventory/domain/entities/movement.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../inventory/presentation/widgets/movement_tile.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/repositories/inventory_export_repository.dart';
import '../providers/reports_providers.dart';

/// Movement history with filters and the CSV export of the inventory.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(movementFilterProvider);
    final movementsAsync = ref.watch(movementHistoryProvider);
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final summaryAsync = ref.watch(inventorySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial y reportes'),
        actions: [
          IconButton(
            tooltip: 'Exportar inventario a CSV',
            onPressed: () => _export(context, ref),
            icon: const Icon(Icons.file_download_outlined),
          ),
          if (!filter.isEmpty)
            IconButton(
              tooltip: 'Limpiar filtros',
              onPressed: () => ref.read(movementFilterProvider.notifier).clear(),
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: summaryAsync.maybeWhen(
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor del inventario',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.money(summary.purchaseValue),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Existencias x precio de compra, sobre '
                      '${summary.activeProductCount} productos activos '
                      'y ${summary.totalUnits} unidades.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                orElse: () => const SizedBox(
                  height: 40,
                  child: Center(child: LinearProgressIndicator()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          productsAsync.maybeWhen(
            data: (products) => _ProductFilter(
              products: products,
              selectedId: filter.productId,
              onChanged: (value) =>
                  ref.read(movementFilterProvider.notifier).setProduct(value),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          _TypeFilter(
            selected: filter.type,
            onChanged: (value) =>
                ref.read(movementFilterProvider.notifier).setType(value),
          ),
          const SizedBox(height: 8),
          _DateRangeFilter(
            from: filter.from,
            to: filter.to,
            onChanged: (from, to) =>
                ref.read(movementFilterProvider.notifier).setRange(from, to),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Movimientos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              movementsAsync.maybeWhen(
                data: (items) => Text(
                  '${items.length} registros',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          movementsAsync.when(
            skipLoadingOnRefresh: true,
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(describeFailure(error)),
            data: (movements) {
              if (movements.isEmpty) {
                return const Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.inbox_outlined),
                    title: Text('Sin movimientos para los filtros aplicados'),
                  ),
                );
              }
              final productNames = <int, String>{
                for (final Product product
                    in productsAsync.value ?? const <Product>[])
                  product.id!: product.name,
              };
              return Column(
                children: [
                  for (final movement in movements)
                    MovementTile(
                      movement: movement,
                      productLabel: productNames[movement.productId],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (productsAsync.hasValue)
            _CategoryBreakdown(
              products: productsAsync.requireValue,
              categoryNames: <int, String>{
                for (final Category category
                    in categoriesAsync.value ?? const <Category>[])
                  category.id: category.name,
              },
            ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = await ref.read(buildInventoryCsvProvider).call(
            includeInactive: true,
          );
      final repository = ref.read(inventoryExportRepositoryProvider);
      final fileName = buildExportFileName('inventario', DateTime.now());
      final path = await repository.writeExport(
        fileName: fileName,
        content: csv,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/csv')],
          subject: 'Inventario de bodega',
          text: 'Exportacion del inventario en formato CSV.',
        ),
      );

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('CSV generado en $path')));
    } on DomainException catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('No fue posible exportar el inventario: $error')),
        );
    }
  }
}

class _ProductFilter extends StatelessWidget {
  const _ProductFilter({
    required this.products,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Product> products;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Producto',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
        for (final product in products)
          DropdownMenuItem<int?>(
            value: product.id,
            child: Text(
              '${product.code} - ${product.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({required this.selected, required this.onChanged});

  final MovementType? selected;
  final ValueChanged<MovementType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final type in MovementType.values)
          ChoiceChip(
            label: Text(type.label),
            selected: selected == type,
            onSelected: (_) => onChanged(type),
          ),
      ],
    );
  }
}

class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter({
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime?, DateTime?) onChanged;

  @override
  Widget build(BuildContext context) {
    final label = from == null || to == null
        ? 'Rango de fechas'
        : '${Formatters.date(from!)} - ${Formatters.date(to!)}';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 1),
                initialDateRange: from != null && to != null
                    ? DateTimeRange(start: from!, end: to!)
                    : null,
              );
              if (range == null) return;
              onChanged(
                DateTime(range.start.year, range.start.month, range.start.day),
                DateTime(
                  range.end.year,
                  range.end.month,
                  range.end.day,
                  23,
                  59,
                  59,
                ),
              );
            },
            icon: const Icon(Icons.date_range),
            label: Text(label, overflow: TextOverflow.ellipsis),
          ),
        ),
        if (from != null || to != null)
          IconButton(
            tooltip: 'Quitar rango',
            onPressed: () => onChanged(null, null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.products,
    required this.categoryNames,
  });

  final List<Product> products;
  final Map<int, String> categoryNames;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final unitsByCategory = <String, int>{};
    final valueByCategory = <String, double>{};
    for (final product in products) {
      final name = categoryNames[product.categoryId] ?? 'Sin categoria';
      unitsByCategory[name] = (unitsByCategory[name] ?? 0) + product.currentStock;
      valueByCategory[name] =
          (valueByCategory[name] ?? 0) + product.stockPurchaseValue;
    }

    final names = unitsByCategory.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen por categoria',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final name in names)
                ListTile(
                  dense: true,
                  title: Text(name),
                  subtitle: Text('${unitsByCategory[name]} unidades'),
                  trailing: Text(
                    Formatters.money(valueByCategory[name] ?? 0),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
