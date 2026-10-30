import '../../../../core/error/domain_exception.dart';
import '../entities/product.dart';
import '../entities/product_draft.dart';
import '../repositories/product_repository.dart';
import '../services/product_validator.dart';

/// Updates the descriptive fields of a product.
///
/// Stock is intentionally not part of the update: it only moves through the
/// inventory ledger.
class UpdateProductUseCase {
  const UpdateProductUseCase(this._products);

  final ProductRepository _products;

  Future<Product> call({required int id, required ProductDraft draft}) async {
    final normalizedCode = ProductValidator.normalizeCode(draft.code);
    ProductValidator.validate(
      code: normalizedCode,
      name: draft.name,
      purchasePrice: draft.purchasePrice,
      salePrice: draft.salePrice,
      minimumStock: draft.minimumStock,
    );

    if (await _products.isCodeTaken(normalizedCode, exceptProductId: id)) {
      throw DuplicateProductCodeException(normalizedCode);
    }

    return _products.update(
      id,
      draft.copyWith(code: normalizedCode, name: draft.name.trim()),
    );
  }
}
