import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/domain_exception.dart';
import '../../../../core/widgets/stock_badge.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/movement.dart';
import '../providers/inventory_providers.dart';

/// Register an entry, an exit or an adjustment for one product.
///
/// The stock arithmetic is not performed here: the use case applies the domain
/// rules and the repository persists movement and stock atomically.
class MovementFormScreen extends ConsumerStatefulWidget {
  const MovementFormScreen({
    super.key,
    required this.productId,
    this.initialType = MovementType.entry,
  });

  final int productId;
  final MovementType initialType;

  @override
  ConsumerState<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends ConsumerState<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  late MovementType _type;
  bool _submitting = false;
  bool _loading = true;
  Product? _product;

  static const Map<MovementType, List<String>> _reasonSuggestions = {
    MovementType.entry: ['Compra', 'Devolucion de cliente', 'Traslado'],
    MovementType.exit: ['Venta', 'Dano', 'Vencimiento', 'Traslado'],
    MovementType.adjustment: [
      'Conteo fisico con diferencia',
      'Correccion de registro',
      'Producto danado no registrado',
    ],
  };

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    try {
      final product = await ref.read(productQueriesProvider).byId(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        if (_type == MovementType.adjustment) {
          _quantityController.text = product.currentStock.toString();
        }
      });
    } on DomainException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar movimiento')),
      body: _loading || product == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.code}  |  stock actual ${product.currentStock}',
                      ),
                      trailing: StockBadge(
                        currentStock: product.currentStock,
                        minimumStock: product.minimumStock,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<MovementType>(
                    segments: const [
                      ButtonSegment(
                        value: MovementType.entry,
                        label: Text('Entrada'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: MovementType.exit,
                        label: Text('Salida'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: MovementType.adjustment,
                        label: Text('Ajuste'),
                        icon: Icon(Icons.tune),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _type = selection.first;
                        _quantityController.text = _type == MovementType.adjustment
                            ? product.currentStock.toString()
                            : '';
                        _reasonController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _type == MovementType.adjustment
                          ? 'Cantidad contada'
                          : 'Cantidad',
                      helperText: _type == MovementType.adjustment
                          ? 'Existencias resultantes del conteo fisico.'
                          : 'Debe ser mayor que cero.',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      if (parsed == null) return 'Ingrese un numero entero';
                      if (_type == MovementType.adjustment) {
                        if (parsed < 0) return 'No puede ser negativo';
                      } else if (parsed <= 0) {
                        return 'Debe ser mayor que cero';
                      }
                      if (_type == MovementType.exit && parsed > product.currentStock) {
                        return 'Solo hay ${product.currentStock} unidades disponibles';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: _type == MovementType.adjustment ? 3 : 1,
                    decoration: InputDecoration(
                      labelText: _type == MovementType.adjustment
                          ? 'Justificacion (obligatoria)'
                          : 'Motivo',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? _type == MovementType.adjustment
                            ? 'La justificacion es obligatoria'
                            : 'El motivo es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final suggestion in _reasonSuggestions[_type]!)
                        ActionChip(
                          label: Text(suggestion),
                          onPressed: () => setState(
                            () => _reasonController.text = suggestion,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _submitting || _product == null ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Confirmar movimiento'),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);

    try {
      final responsible = await ref.read(responsibleNameProvider.future);
      final movement = await ref.read(registerMovementProvider).call(
            productId: widget.productId,
            type: _type,
            quantity: int.parse(_quantityController.text.trim()),
            reason: _reasonController.text.trim(),
            responsible: responsible,
          );

      ref.read(productStockRevisionProvider.notifier).bump();
      ref.invalidate(productDetailProvider(widget.productId));

      if (!mounted) return;
      _showMessage(
        'Movimiento registrado. Stock resultante: ${movement.resultingStock}.',
      );
      Navigator.of(context).pop(true);
    } on DomainException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage(describeFailure(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
