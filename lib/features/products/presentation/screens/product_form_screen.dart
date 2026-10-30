import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/domain_exception.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/product_draft.dart';
import '../../domain/services/product_validator.dart';
import '../providers/product_providers.dart';
import 'product_detail_screen.dart';

/// Create and edit form for a product.
///
/// The initial stock field is only offered while creating: it becomes an entry
/// movement, never a direct column value.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final int? productId;

  bool get isEditing => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchaseController = TextEditingController();
  final _saleController = TextEditingController();
  final _minimumController = TextEditingController(text: '5');
  final _initialStockController = TextEditingController(text: '0');

  int? _categoryId;
  String? _photoPath;
  bool _active = true;
  bool _submitting = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    try {
      final product = await ref.read(productQueriesProvider).byId(widget.productId!);
      if (!mounted) return;
      setState(() {
        _codeController.text = product.code;
        _nameController.text = product.name;
        _descriptionController.text = product.description ?? '';
        _purchaseController.text = product.purchasePrice.toStringAsFixed(2);
        _saleController.text = product.salePrice.toStringAsFixed(2);
        _minimumController.text = product.minimumStock.toString();
        _categoryId = product.categoryId;
        _photoPath = product.photoPath;
        _active = product.active;
      });
    } on DomainException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purchaseController.dispose();
    _saleController.dispose();
    _minimumController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Codigo unico',
                      helperText: 'Se usa para el codigo de barras y el QR.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final code = ProductValidator.normalizeCode(value ?? '');
                      if (code.isEmpty) return 'El codigo es obligatorio';
                      if (code.contains(' ')) {
                        return 'El codigo no puede contener espacios';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripcion (opcional)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  categories.maybeWhen(
                    data: (items) => DropdownButtonFormField<int?>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sin categoria'),
                        ),
                        for (final category in items)
                          DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _categoryId = value),
                    ),
                    orElse: () => const LinearProgressIndicator(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchaseController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Precio compra',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePrice,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _saleController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Precio venta',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePrice,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minimumController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Stock minimo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      if (parsed == null) return 'Ingrese un numero entero';
                      if (parsed < 0) return 'No puede ser negativo';
                      return null;
                    },
                  ),
                  if (!widget.isEditing) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _initialStockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Stock inicial',
                        helperText:
                            'Se registra como movimiento de entrada.',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null) return 'Ingrese un numero entero';
                        if (parsed < 0) return 'No puede ser negativo';
                        return null;
                      },
                    ),
                  ],
                  if (widget.isEditing) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                      title: const Text('Producto activo'),
                      subtitle: const Text(
                        'Un producto inactivo no aparece en el listado.',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PhotoPicker(
                    photoPath: _photoPath,
                    onChanged: (path) => setState(() => _photoPath = path),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(widget.isEditing ? 'Guardar cambios' : 'Crear producto'),
          ),
        ),
      ),
    );
  }

  String? _validatePrice(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Ingrese un precio';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Ingrese un numero valido';
    if (parsed <= 0) return 'Debe ser mayor que cero';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);

    final draft = ProductDraft(
      code: ProductValidator.normalizeCode(_codeController.text),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryId: _categoryId,
      purchasePrice: double.parse(_purchaseController.text.trim()),
      salePrice: double.parse(_saleController.text.trim()),
      minimumStock: int.parse(_minimumController.text.trim()),
      photoPath: _photoPath,
      active: _active,
    );

    try {
      final responsible = await ref.read(responsibleNameProvider.future);
      final saved = await ref.read(saveProductProvider).call(
            productId: widget.productId,
            draft: draft,
            initialStock: widget.isEditing
                ? 0
                : int.parse(_initialStockController.text.trim()),
            responsible: responsible,
          );
      if (!mounted) return;
      _showMessage(widget.isEditing ? 'Producto actualizado.' : 'Producto creado.');
      if (widget.isEditing) {
        Navigator.of(context).pop(saved);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ProductDetailScreen(productId: saved.id!),
          ),
        );
      }
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

class _PhotoPicker extends ConsumerWidget {
  const _PhotoPicker({required this.photoPath, required this.onChanged});

  final String? photoPath;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final file = photoPath == null ? null : File(photoPath!);
    final exists = file?.existsSync() ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotografia (opcional)', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: exists
                  ? Image.file(file!, fit: BoxFit.cover)
                  : Icon(
                      Icons.image_outlined,
                      color: theme.colorScheme.outline,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 80,
                        );
                        if (picked != null) {
                          onChanged(picked.path);
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No fue posible acceder a la galeria.',
                                ),
                              ),
                            );
                        }
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Elegir imagen'),
                  ),
                  if (exists)
                    TextButton.icon(
                      onPressed: () => onChanged(null),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Quitar'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
