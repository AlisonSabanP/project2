import '../../../../core/error/domain_exception.dart';
import '../entities/product.dart';
import '../entities/product_draft.dart';
import '../repositories/product_repository.dart';
import '../services/product_validator.dart';

/// Creates a product and turns any initial stock into an entry movement.
///
/// The uniqueness check happens before persisting so the user gets a precise
/// error instead of a database constraint failure.
class CreateProductUseCase {
  const CreateProductUseCase(this._products);

  final ProductRepository _products;

  Future<Product> call({
    required ProductDraft draft,
    int initialStock = 0,
    required String responsible,
  }) async {
    final normalizedCode = ProductValidator.normalizeCode(draft.code);
    ProductValidator.validate(
      code: normalizedCode,
      name: draft.name,
      purchasePrice: draft.purchasePrice,
      salePrice: draft.salePrice,
      minimumStock: draft.minimumStock,
      initialStock: initialStock,
    );

    if (await _products.isCodeTaken(normalizedCode)) {
      throw DuplicateProductCodeException(normalizedCode);
    }

    return _products.create(
      draft.copyWith(code: normalizedCode, name: draft.name.trim()),
      initialStock: initialStock,
      responsible: responsible,
    );
  }
}
