import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/error/domain_exception.dart';
import '../../../inventory/domain/entities/movement.dart';
import '../../../inventory/presentation/screens/movement_form_screen.dart';
import '../../../products/domain/entities/product.dart';
import '../providers/scanner_providers.dart';
import '../widgets/manual_code_search.dart';
import 'unknown_code_sheet.dart';

/// Camera reader for Code 128 barcodes and QR codes.
///
/// The scanned payload is always the product code; the lookup is delegated to
/// [resolveScannedCodeProvider] so the widget holds no inventory logic.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.code128, BarcodeFormat.qrCode],
  );

  bool _handling = false;
  bool _manualMode = false;
  Product? _lastProduct;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaner'),
        actions: [
          IconButton(
            tooltip: _manualMode ? 'Usar camara' : 'Busqueda manual',
            onPressed: () => setState(() => _manualMode = !_manualMode),
            icon: Icon(_manualMode ? Icons.qr_code_scanner : Icons.keyboard),
          ),
          if (!_manualMode)
            IconButton(
              tooltip: 'Linterna',
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flashlight_on_outlined),
            ),
        ],
      ),
      body: _manualMode
          ? ManualCodeSearch(
              onProductSelected: (product) => _showProduct(product),
            )
          : Column(
              children: [
                Expanded(
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) =>
                        _ScannerError(error: error),
                  ),
                ),
                _ScannerFooter(lastProduct: _lastProduct),
              ],
            ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    String? code;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        code = value;
        break;
      }
    }
    if (code == null) return;

    _handling = true;
    try {
      await _controller.stop();
      final resolution = await ref.read(resolveScannedCodeProvider).call(code);
      if (!mounted) return;

      final product = resolution.product;
      if (product == null) {
        await showUnknownCodeSheet(context, resolution.code);
      } else {
        await _showProduct(product);
      }
    } on DomainException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('No fue posible leer el codigo: $error');
    } finally {
      _handling = false;
      if (mounted) {
        await _controller.start();
      }
    }
  }

  Future<void> _showProduct(Product product) async {
    setState(() => _lastProduct = product);

    final action = await showModalBottomSheet<MovementType>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProductSheet(product: product),
    );
    if (!mounted) return;

    if (action == null) {
      _showMessage('Producto ${product.code} localizado.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MovementFormScreen(
          productId: product.id!,
          initialType: action,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = error.errorCode;
    final message = switch (code) {
      MobileScannerErrorCode.permissionDenied =>
        'La aplicacion no tiene permiso para usar la camara. '
            'Habilite el permiso de camara en los ajustes del sistema.',
      MobileScannerErrorCode.unsupported =>
        'Este dispositivo no admite la lectura con camara. '
            'Use la busqueda manual por codigo o nombre.',
      _ =>
        'No fue posible iniciar la camara. '
            'Use la busqueda manual por codigo o nombre.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined,
                size: 44, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ScannerFooter extends StatelessWidget {
  const _ScannerFooter({required this.lastProduct});

  final Product? lastProduct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lastProduct == null
                ? 'Apunten el codigo de barras o el QR al centro de la pantalla.'
                : 'Ultimo producto: ${lastProduct!.name} '
                    '(${lastProduct!.code}) - ${lastProduct!.currentStock} unidades.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ProductSheet extends StatelessWidget {
  const _ProductSheet({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Codigo: ${product.code}'),
            Text('Existencias: ${product.currentStock}'),
            Text('Stock minimo: ${product.minimumStock}'),
            if (product.isLowStock) ...[
              const SizedBox(height: 8),
              Text(
                'Stock igual o inferior al minimo.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        Navigator.of(context).pop(MovementType.entry),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Entrada'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        Navigator.of(context).pop(MovementType.exit),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Salida'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        Navigator.of(context).pop(MovementType.adjustment),
                    icon: const Icon(Icons.tune),
                    label: const Text('Ajuste'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
