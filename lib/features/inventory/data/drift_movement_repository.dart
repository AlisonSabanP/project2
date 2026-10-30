import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart' as db;
import '../../inventory/domain/entities/movement.dart';
import '../../inventory/domain/entities/movement_filter.dart';
import '../../inventory/domain/repositories/movement_repository.dart';
import '../../../core/database/mappers.dart';

/// Drift backed ledger.
///
/// [register] writes the movement row and the new stock level inside one
/// transaction, so a failure leaves both tables untouched.
class DriftMovementRepository implements MovementRepository {
  DriftMovementRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<Movement>> watchAll({
    MovementFilter filter = const MovementFilter(),
  }) {
    return _applyFilter(_db.select(_db.movements), filter)
        .watch()
        .map(_toDomain);
  }

  @override
  Stream<List<Movement>> watchByProduct(int productId, {int? limit}) {
    final query = _db.select(_db.movements)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.recordedAt,
              mode: drift.OrderingMode.desc,
            ),
        (t) => drift.OrderingTerm(
              expression: t.id,
              mode: drift.OrderingMode.desc,
            ),
      ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query.watch().map(_toDomain);
  }

  @override
  Future<List<Movement>> findAll({
    MovementFilter filter = const MovementFilter(),
    int? limit,
  }) async {
    final query = _applyFilter(_db.select(_db.movements), filter);
    if (limit != null) {
      query.limit(limit);
    }
    return _toDomain(await query.get());
  }

  @override
  Future<List<MovementWithProduct>> findDetailed({
    MovementFilter filter = const MovementFilter(),
    int? limit,
  }) async {
    final query = _db.select(_db.movements).join([
      drift.innerJoin(
        _db.products,
        _db.products.id.equalsExp(_db.movements.productId),
      ),
    ]);

    if (filter.productId != null) {
      query.where(_db.movements.productId.equals(filter.productId!));
    }
    if (filter.type != null) {
      query.where(
        _db.movements.type.equals(MovementMapper.typeToColumn(filter.type!)),
      );
    }
    if (filter.from != null) {
      query.where(_db.movements.recordedAt.isBiggerOrEqualValue(filter.from!));
    }
    if (filter.to != null) {
      query.where(_db.movements.recordedAt.isSmallerOrEqualValue(filter.to!));
    }

    query.orderBy([
      drift.OrderingTerm(
        expression: _db.movements.recordedAt,
        mode: drift.OrderingMode.desc,
      ),
      drift.OrderingTerm(
        expression: _db.movements.id,
        mode: drift.OrderingMode.desc,
      ),
    ]);
    if (limit != null) {
      query.limit(limit);
    }

    final rows = await query.get();
    return rows
        .map(
          (row) => MovementWithProduct(
            movement: MovementMapper.toDomain(row.readTable(_db.movements)),
            productName: row.readTable(_db.products).name,
            productCode: row.readTable(_db.products).code,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<int> countByProduct(int productId) async {
    final countExp = _db.movements.id.count();
    final query = _db.selectOnly(_db.movements)
      ..addColumns([countExp])
      ..where(_db.movements.productId.equals(productId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<Movement> register(Movement movement) async {
    final id = await _db.transaction(() async {
      final movementId = await _db
          .into(_db.movements)
          .insert(CompanionFactory.movementInsert(movement));

      await (_db.update(_db.products)
            ..where((t) => t.id.equals(movement.productId)))
          .write(
        db.ProductsCompanion(
          currentStock: drift.Value(movement.resultingStock),
        ),
      );
      return movementId;
    });

    return Movement(
      id: id,
      productId: movement.productId,
      type: movement.type,
      quantity: movement.quantity,
      previousStock: movement.previousStock,
      resultingStock: movement.resultingStock,
      reason: movement.reason,
      responsible: movement.responsible,
      dateTime: movement.dateTime,
    );
  }

  drift.SimpleSelectStatement<db.$MovementsTable, db.Movement> _applyFilter(
    drift.SimpleSelectStatement<db.$MovementsTable, db.Movement> query,
    MovementFilter filter,
  ) {
    if (filter.productId != null) {
      query.where((t) => t.productId.equals(filter.productId!));
    }
    if (filter.type != null) {
      final columnType = MovementMapper.typeToColumn(filter.type!);
      query.where((t) => t.type.equals(columnType));
    }
    if (filter.from != null) {
      final from = filter.from!;
      query.where((t) => t.recordedAt.isBiggerOrEqualValue(from));
    }
    if (filter.to != null) {
      final to = filter.to!;
      query.where((t) => t.recordedAt.isSmallerOrEqualValue(to));
    }
    query.orderBy([
      (t) => drift.OrderingTerm(
            expression: t.recordedAt,
            mode: drift.OrderingMode.desc,
          ),
      (t) => drift.OrderingTerm(
            expression: t.id,
            mode: drift.OrderingMode.desc,
          ),
    ]);
    return query;
  }

  List<Movement> _toDomain(List<db.Movement> rows) =>
      rows.map(MovementMapper.toDomain).toList(growable: false);
}
