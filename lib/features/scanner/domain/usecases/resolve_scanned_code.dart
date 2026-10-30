import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/product_queries.dart';

/// Outcome of interpreting a scanned payload.
class ScanResolution {
  const ScanResolution({
    required this.rawValue,
    required this.code,
    this.product,
  });

  /// Exactly what the camera decoded.
  final String rawValue;

  /// Normalized code extracted from [rawValue].
  final String code;

  /// The matching product, or `null` when the code is not registered.
  final Product? product;

  bool get isRegistered => product != null;
}

/// Turns a decoded barcode or QR payload into a product lookup.
///
/// Both label types carry the unique product code only, so the payload is used
/// verbatim after trimming. The QR never encodes quantities, which keeps labels
/// valid after every stock change.
class ResolveScannedCodeUseCase {
  const ResolveScannedCodeUseCase(this._products);

  final ProductQueries _products;

  Future<ScanResolution> call(String rawValue) async {
    final code = rawValue.trim().toUpperCase();
    if (code.isEmpty) {
      return const ScanResolution(rawValue: '', code: '');
    }
    final product = await _products.byCode(code);
    return ScanResolution(rawValue: rawValue, code: code, product: product);
  }
}
