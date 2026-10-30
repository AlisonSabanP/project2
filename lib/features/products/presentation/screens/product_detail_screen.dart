import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/domain_exception.dart';
import '../../../../core/formatting/formatters.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/stock_badge.dart';
import '../../../inventory/domain/entities/movement.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../inventory/presentation/screens/movement_form_screen.dart';
import '../../../inventory/presentation/widgets/movement_tile.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';
import '../widgets/product_label.dart';
import 'product_form_screen.dart';

/// Detail of a single product: data, stock, label and its movement history.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _labelKey = GlobalKey();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        actions: [
          productAsync.maybeWhen(
            data: (product) => PopupMenuButton<String>(
              onSelected: (value) => _handleAction(value, product),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'toggle', child: Text('Activar / Desactivar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueView<Product>(
        value: productAsync,
        onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        builder: (context, product) => _buildBody(context, product),
      ),
      floatingActionButton: productAsync.maybeWhen(
        data: (product) => FloatingActionButton.extended(
          onPressed: () => _openMovement(product, MovementType.entry),
          icon: const Icon(Icons.swap_vert),
          label: const Text('Movimiento'),
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildBody(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final movements = ref.watch(productMovementProvider(product.id!));
    final visuals = StockStatus.of(
      context,
      currentStock: product.currentStock,
      minimumStock: product.minimumStock,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        if (product.photoPath != null &&
            File(product.photoPath!).existsSync())
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(product.photoPath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!product.active)
                      Chip(
                        label: const Text('Inactivo'),
                        backgroundColor: theme.colorScheme.errorContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Codigo: ${product.code}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(product.description!, style: theme.textTheme.bodyMedium),
                ],
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Existencias',
                        value: '${product.currentStock}',
                        emphasis: visuals.color,
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Stock minimo',
                        value: '${product.minimumStock}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Precio compra',
                        value: Formatters.money(product.purchasePrice),
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Precio venta',
                        value: Formatters.money(product.salePrice),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Metric(
                  label: 'Valor del inventario (compra)',
                  value: Formatters.money(product.stockPurchaseValue),
                ),
                if (product.isLowStock) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.currentStock <= 0
                                ? 'Producto agotado. Registre una entrada.'
                                : 'Stock igual o inferior al minimo.',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          onEntry: () => _openMovement(product, MovementType.entry),
          onExit: () => _openMovement(product, MovementType.exit),
          onAdjustment: () => _openMovement(product, MovementType.adjustment),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Etiqueta de codigos',
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: _busy ? null : () => _shareLabel(product),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir'),
            ),
          ],
        ),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ProductLabel(
              labelKey: _labelKey,
              productName: product.name,
              code: product.code,
              priceLabel: Formatters.money(product.salePrice),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Codigos individuales', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: product.code,
                  height: 90,
                  drawText: true,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: product.code,
                  width: 160,
                  height: 160,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'El QR contiene unicamente el codigo ${product.code}.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Movimientos recientes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        movements.when(
          skipLoadingOnRefresh: true,
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(describeFailure(error)),
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Aun no hay movimientos para este producto.'),
              );
            }
            return Column(
              children: [
                for (final movement in items.take(8))
                  MovementTile(movement: movement),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openMovement(Product product, MovementType type) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MovementFormScreen(
          productId: product.id!,
          initialType: type,
        ),
      ),
    );
    if (mounted) {
      ref.invalidate(productDetailProvider(widget.productId));
    }
  }

  Future<void> _shareLabel(Product product) async {
    setState(() => _busy = true);
    try {
      final bytes = await captureLabelBytes(_labelKey);
      final repository = ref.read(labelExportRepositoryProvider);
      final path = await repository.saveLabel(
        productCode: product.code,
        pngBytes: bytes,
      );
      await repository.shareLabel(
        path: path,
        title: 'Etiqueta ${product.code} - ${product.name}',
      );
      if (mounted) {
        _showMessage('Etiqueta generada en $path');
      }
    } on DomainException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) {
        _showMessage('No fue posible exportar la etiqueta: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleAction(String action, Product product) async {
    switch (action) {
      case 'edit':
        final result = await Navigator.of(context).push(
          MaterialPageRoute<Product>(
            builder: (_) => ProductFormScreen(productId: product.id),
          ),
        );
        if (result != null) {
          ref.invalidate(productDetailProvider(widget.productId));
        }
      case 'toggle':
        try {
          await ref.read(setProductActiveProvider).call(
                id: product.id!,
                active: !product.active,
              );
          ref.invalidate(productDetailProvider(widget.productId));
          ref.invalidate(productListProvider);
          if (mounted) {
            _showMessage(
              product.active ? 'Producto desactivado.' : 'Producto activado.',
            );
          }
        } on DomainException catch (error) {
          if (mounted) _showMessage(error.message);
        }
      case 'delete':
        await _confirmDelete(product);
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          'Se eliminara "${product.name}" de forma permanente. '
          'Esta accion solo es posible si no tiene movimientos registrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(deleteProductProvider).call(product.id!);
      if (!mounted) return;
      ref.invalidate(productListProvider);
      _showMessage('Producto eliminado.');
      Navigator.of(context).pop();
    } on DomainException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.emphasis});

  final String label;
  final String value;
  final Color? emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: emphasis,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onEntry,
    required this.onExit,
    required this.onAdjustment,
  });

  final VoidCallback onEntry;
  final VoidCallback onExit;
  final VoidCallback onAdjustment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onEntry,
            icon: const Icon(Icons.arrow_downward),
            label: const Text('Entrada'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onExit,
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Salida'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onAdjustment,
            icon: const Icon(Icons.tune),
            label: const Text('Ajuste'),
          ),
        ),
      ],
    );
  }
}
