import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Builds the printable label of a product: name, code, Code 128 barcode and
/// QR code.
///
/// Both symbols encode the product code only. Quantities and stock are never
/// printed, so a label stays valid after every inventory movement.
class ProductLabel extends StatelessWidget {
  const ProductLabel({
    super.key,
    required this.productName,
    required this.code,
    this.priceLabel,
    this.labelKey,
  });

  final String productName;
  final String code;
  final String? priceLabel;
  final Key? labelKey;

  static const double labelWidth = 380;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      key: labelKey,
      child: Container(
        width: labelWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              productName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              code,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.black54,
                letterSpacing: 1.4,
              ),
            ),
            if (priceLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                priceLabel!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),
            BarcodeWidget(
              barcode: Barcode.code128(),
              data: code,
              width: labelWidth - 48,
              height: 72,
              drawText: false,
              color: Colors.black,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              code,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black87,
                letterSpacing: 2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            BarcodeWidget(
              barcode: Barcode.qrCode(errorCorrectLevel: BarcodeQRCorrectionLevel.medium),
              data: code,
              width: 132,
              height: 132,
              color: Colors.black,
              backgroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rasterises a widget subtree into PNG bytes for sharing or printing.
Future<Uint8List> captureLabelBytes(GlobalKey key, {double pixelRatio = 3}) async {
  final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('La etiqueta aun no esta lista para exportarse.');
  }
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('No fue posible generar la imagen de la etiqueta.');
  }
  return byteData.buffer.asUint8List();
}
