import '../../../../core/error/domain_exception.dart';
import '../entities/movement.dart';

/// Result of applying a movement to a stock level.
class StockOutcome {
  const StockOutcome({required this.previousStock, required this.resultingStock});

  final int previousStock;
  final int resultingStock;

  int get delta => resultingStock - previousStock;
}

/// Pure inventory rules.
///
/// This class holds no widgets, no database access and no mutable state, so it
/// can be exercised directly by unit tests and reused by every feature.
abstract final class InventoryRules {
  /// Rejects zero and negative quantities for entries and exits.
  static void validatePositiveQuantity(int quantity) {
    if (quantity <= 0) {
      throw const NonPositiveQuantityException();
    }
  }

  /// An adjustment records a counted stock, which may legitimately be zero but
  /// never negative.
  static void validateCountedQuantity(int quantity) {
    if (quantity < 0) {
      throw const ValidationException(
        'La cantidad contada no puede ser negativa.',
      );
    }
  }

  /// Guards exits so stock never becomes negative.
  static void validateSufficientStock({
    required int available,
    required int requested,
  }) {
    if (requested > available) {
      throw InsufficientStockException(
        available: available,
        requested: requested,
      );
    }
  }

  static void validateReason(String reason) {
    if (reason.trim().isEmpty) {
      throw const MissingReasonException('motivo');
    }
  }

  /// Adjustments always require an explicit justification.
  static void validateJustification(String justification) {
    if (justification.trim().isEmpty) {
      throw const MissingJustificationException();
    }
  }

  /// Computes the stock level produced by a movement.
  ///
  /// For [MovementType.entry] the quantity is added, for
  /// [MovementType.exit] it is subtracted and for [MovementType.adjustment]
  /// the quantity *is* the counted stock.
  static StockOutcome apply({
    required MovementType type,
    required int previousStock,
    required int quantity,
  }) {
    switch (type) {
      case MovementType.entry:
        validatePositiveQuantity(quantity);
        return StockOutcome(
          previousStock: previousStock,
          resultingStock: previousStock + quantity,
        );
      case MovementType.exit:
        validatePositiveQuantity(quantity);
        validateSufficientStock(available: previousStock, requested: quantity);
        return StockOutcome(
          previousStock: previousStock,
          resultingStock: previousStock - quantity,
        );
      case MovementType.adjustment:
        validateCountedQuantity(quantity);
        return StockOutcome(
          previousStock: previousStock,
          resultingStock: quantity,
        );
    }
  }

  /// Full validation of an incoming movement request, combining the per type
  /// rules with the shared ones.
  static StockOutcome validateAndApply({
    required MovementType type,
    required int previousStock,
    required int quantity,
    required String reason,
  }) {
    switch (type) {
      case MovementType.entry:
      case MovementType.exit:
        validatePositiveQuantity(quantity);
        validateReason(reason);
      case MovementType.adjustment:
        validateJustification(reason);
    }
    return apply(type: type, previousStock: previousStock, quantity: quantity);
  }
}
