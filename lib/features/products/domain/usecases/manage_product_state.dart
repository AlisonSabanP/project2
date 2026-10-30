import '../../../../core/error/domain_exception.dart';
import '../repositories/product_repository.dart';

/// Deactivates or reactivates a product.
///
/// Deactivation is the only removal path offered to the user: the record and
/// its history stay intact.
class SetProductActiveUseCase {
  const SetProductActiveUseCase(this._products);

  final ProductRepository _products;

  Future<void> call({required int id, required bool active}) {
    return _products.setActive(id, active: active);
  }
}

/// Physically deletes a product, but only when it has no movements.
class DeleteProductUseCase {
  const DeleteProductUseCase(this._products);

  final ProductRepository _products;

  Future<void> call(int id) async {
    if (await _products.hasMovements(id)) {
      throw const ProductHasMovementsException();
    }
    await _products.delete(id);
  }
}
