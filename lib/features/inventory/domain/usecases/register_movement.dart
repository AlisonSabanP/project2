import '../../../products/domain/repositories/product_repository.dart';
import '../../../../core/error/domain_exception.dart';
import '../entities/movement.dart';
import '../repositories/movement_repository.dart';
import '../services/inventory_rules.dart';

/// Records an inventory movement and updates the stock of the product.
///
/// The stock arithmetic lives in [InventoryRules]; this use case loads the
/// current stock, applies the rules and delegates persistence to the
/// repository, which performs the ledger insert and the stock update inside a
/// single database transaction.
class RegisterMovementUseCase {
  const RegisterMovementUseCase({
    required ProductRepository products,
    required MovementRepository movements,
    DateTime Function() clock = DateTime.now,
  })  : _products = products,
        _movements = movements,
        _clock = clock;

  final ProductRepository _products;
  final MovementRepository _movements;
  final DateTime Function() _clock;

  Future<Movement> call({
    required int productId,
    required MovementType type,
    required int quantity,
    required String reason,
    required String responsible,
  }) async {
    final product = await _products.findById(productId);
    if (product == null) {
      throw ProductByIdNotFoundException(productId);
    }

    final outcome = InventoryRules.validateAndApply(
      type: type,
      previousStock: product.currentStock,
      quantity: quantity,
      reason: reason,
    );

    final movement = Movement(
      productId: productId,
      type: type,
      quantity: quantity,
      previousStock: outcome.previousStock,
      resultingStock: outcome.resultingStock,
      reason: reason.trim(),
      responsible: responsible.trim().isEmpty ? 'Sin asignar' : responsible.trim(),
      dateTime: _clock(),
    );

    return _movements.register(movement);
  }
}
