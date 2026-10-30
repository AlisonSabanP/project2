import '../entities/movement.dart';
import '../entities/movement_filter.dart';
import '../repositories/movement_repository.dart';

/// Read side of the movement ledger.
class MovementQueries {
  const MovementQueries(this._movements);

  final MovementRepository _movements;

  Stream<List<Movement>> watchAll({MovementFilter filter = const MovementFilter()}) =>
      _movements.watchAll(filter: filter);

  Stream<List<Movement>> watchByProduct(int productId, {int? limit}) =>
      _movements.watchByProduct(productId, limit: limit);

  Future<List<Movement>> all({
    MovementFilter filter = const MovementFilter(),
    int? limit,
  }) =>
      _movements.findAll(filter: filter, limit: limit);

  Future<List<MovementWithProduct>> detailed({
    MovementFilter filter = const MovementFilter(),
    int? limit,
  }) =>
      _movements.findDetailed(filter: filter, limit: limit);

  Future<int> countByProduct(int productId) =>
      _movements.countByProduct(productId);
}
