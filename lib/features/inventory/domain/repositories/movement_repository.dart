import '../entities/movement.dart';
import '../entities/movement_filter.dart';

/// A movement joined with the product it belongs to, ready for display.
class MovementWithProduct {
  const MovementWithProduct({
    required this.movement,
    required this.productName,
    required this.productCode,
  });

  final Movement movement;
  final String productName;
  final String productCode;
}

/// Persistence contract for the movement ledger.
///
/// The ledger is append only: implementations expose no update or delete
/// operations for confirmed movements.
abstract interface class MovementRepository {
  /// Reactive feed, newest first.
  Stream<List<Movement>> watchAll({
    MovementFilter filter = const MovementFilter(),
  });

  Stream<List<Movement>> watchByProduct(int productId, {int? limit});

  Future<List<Movement>> findAll({
    MovementFilter filter = const MovementFilter(),
    int? limit,
  });

  Future<List<MovementWithProduct>> findDetailed({
    MovementFilter filter = const MovementFilter(),
    int? limit,
  });

  Future<int> countByProduct(int productId);

  /// Atomically records the movement and updates the product stock.
  ///
  /// Returns the persisted movement including its assigned identifier.
  Future<Movement> register(Movement movement);
}
