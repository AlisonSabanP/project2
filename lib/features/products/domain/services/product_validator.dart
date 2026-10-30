import '../../../../core/error/domain_exception.dart';
import '../../../inventory/domain/services/inventory_rules.dart';

/// Validates the data typed by the user for a product.
///
/// Kept in the domain so both the create and update flows, and the unit tests,
/// share exactly the same rules.
abstract final class ProductValidator {
  static const int maxCodeLength = 40;
  static const int maxNameLength = 120;

  static String normalizeCode(String code) => code.trim().toUpperCase();

  /// Validates the mutable attributes of a product.
  ///
  /// [initialStock] is only meaningful when creating a product: it becomes an
  /// entry movement instead of a direct column value.
  static void validate({
    required String code,
    required String name,
    required double purchasePrice,
    required double salePrice,
    required int minimumStock,
    int? initialStock,
  }) {
    final normalized = normalizeCode(code);
    if (normalized.isEmpty) {
      throw const ValidationException('El codigo es obligatorio.');
    }
    if (normalized.length > maxCodeLength) {
      throw const ValidationException(
        'El codigo no puede superar $maxCodeLength caracteres.',
      );
    }
    if (normalized.contains(RegExp(r'\s'))) {
      throw const ValidationException(
        'El codigo no puede contener espacios.',
      );
    }
    if (name.trim().isEmpty) {
      throw const ValidationException('El nombre es obligatorio.');
    }
    if (name.trim().length > maxNameLength) {
      throw const ValidationException(
        'El nombre no puede superar $maxNameLength caracteres.',
      );
    }
    if (purchasePrice <= 0) {
      throw const ValidationException(
        'El precio de compra debe ser mayor que cero.',
      );
    }
    if (salePrice <= 0) {
      throw const ValidationException(
        'El precio de venta debe ser mayor que cero.',
      );
    }
    if (salePrice < purchasePrice) {
      throw const ValidationException(
        'El precio de venta no puede ser menor que el precio de compra.',
      );
    }
    if (minimumStock < 0) {
      throw const ValidationException(
        'El stock minimo no puede ser negativo.',
      );
    }
    if (initialStock != null) {
      InventoryRules.validateCountedQuantity(initialStock);
    }
  }

  /// Reason used by the automatic entry movement created with a new product.
  static String initialStockReason(int quantity) =>
      'Existencia inicial de $quantity unidades';
}
