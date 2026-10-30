import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart' as db;
import '../../../core/error/domain_exception.dart';
import '../../inventory/domain/entities/movement.dart';
import '../domain/entities/product.dart';
import '../domain/entities/product_draft.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/services/product_validator.dart';
import '../../../core/database/mappers.dart';

/// Drift backed implementation of [ProductRepository].
class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<Product>> watchAll({bool includeInactive = false}) {
    return _activeQuery(includeInactive: includeInactive)
        .watch()
        .map(_toDomainList);
  }

  @override
  Future<List<Product>> findAll({bool includeInactive = false}) async {
    final rows = await _activeQuery(includeInactive: includeInactive).get();
    return _toDomainList(rows);
  }

  @override
  Future<Product?> findById(int id) async {
    final row = await (_db.select(_db.products)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : ProductMapper.toDomain(row);
  }

  @override
  Future<Product?> findByCode(String code) async {
    final normalized = ProductValidator.normalizeCode(code);
    final row = await (_db.select(_db.products)
          ..where((t) => t.code.equals(normalized)))
        .getSingleOrNull();
    return row == null ? null : ProductMapper.toDomain(row);
  }

  @override
  Future<List<Product>> search(
    String term, {
    bool includeInactive = false,
  }) async {
    final query = _activeQuery(includeInactive: includeInactive);
    final normalized = term.trim();
    if (normalized.isNotEmpty) {
      final pattern = '%${normalized.toUpperCase()}%';
      query.where(
        (t) => t.code.upper().like(pattern) | t.name.upper().like(pattern),
      );
    }
    final rows = await query.get();
    return _toDomainList(rows);
  }

  @override
  Future<List<Product>> findLowStock({bool includeInactive = false}) async {
    final query = _activeQuery(includeInactive: includeInactive)
      ..where((t) => t.currentStock.isSmallerOrEqual(t.minimumStock));
    final rows = await query.get();
    return _toDomainList(rows);
  }

  @override
  Future<int> countAll({bool includeInactive = false}) async {
    final countExp = _db.products.id.count();
    final query = _db.selectOnly(_db.products)..addColumns([countExp]);
    if (!includeInactive) {
      query.where(_db.products.active.equals(true));
    }
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<bool> isCodeTaken(String code, {int? exceptProductId}) async {
    final normalized = ProductValidator.normalizeCode(code);
    final query = _db.selectOnly(_db.products)
      ..addColumns([_db.products.id])
      ..where(_db.products.code.equals(normalized));
    if (exceptProductId != null) {
      query.where(_db.products.id.equals(exceptProductId).not());
    }
    return (await query.getSingleOrNull()) != null;
  }

  @override
  Future<Product> create(
    ProductDraft draft, {
    int initialStock = 0,
    String responsible = '',
  }) async {
    ProductValidator.validate(
      code: draft.code,
      name: draft.name,
      purchasePrice: draft.purchasePrice,
      salePrice: draft.salePrice,
      minimumStock: draft.minimumStock,
      initialStock: initialStock,
    );

    final productId = await _db.transaction(() async {
      final id = await _db.into(_db.products).insert(
            CompanionFactory.productInsert(
              code: draft.code,
              name: draft.name,
              description: draft.description,
              categoryId: draft.categoryId,
              purchasePrice: draft.purchasePrice,
              salePrice: draft.salePrice,
              minimumStock: draft.minimumStock,
              photoPath: draft.photoPath,
              active: draft.active,
            ),
          );

      if (initialStock > 0) {
        await _db.into(_db.movements).insert(
              CompanionFactory.movementInsert(
                Movement(
                  productId: id,
                  type: MovementType.entry,
                  quantity: initialStock,
                  previousStock: 0,
                  resultingStock: initialStock,
                  reason: ProductValidator.initialStockReason(initialStock),
                  responsible: responsible.trim().isEmpty
                      ? 'Sin asignar'
                      : responsible.trim(),
                  dateTime: DateTime.now(),
                ),
              ),
            );
        await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
          db.ProductsCompanion(currentStock: drift.Value(initialStock)),
        );
      }
      return id;
    });

    final created = await findById(productId);
    if (created == null) {
      throw const ProductNotFoundException();
    }
    return created;
  }

  @override
  Future<Product> update(int id, ProductDraft draft) async {
    ProductValidator.validate(
      code: draft.code,
      name: draft.name,
      purchasePrice: draft.purchasePrice,
      salePrice: draft.salePrice,
      minimumStock: draft.minimumStock,
    );

    final updated = await (_db.update(_db.products)..where((t) => t.id.equals(id)))
        .write(
      db.ProductsCompanion(
        code: drift.Value(draft.code),
        name: drift.Value(draft.name),
        description: drift.Value(draft.description),
        categoryId: drift.Value(draft.categoryId),
        purchasePrice: drift.Value(draft.purchasePrice),
        salePrice: drift.Value(draft.salePrice),
        minimumStock: drift.Value(draft.minimumStock),
        photoPath: drift.Value(draft.photoPath),
        active: drift.Value(draft.active),
      ),
    );

    if (updated == 0) {
      throw ProductByIdNotFoundException(id);
    }
    final product = await findById(id);
    if (product == null) {
      throw ProductByIdNotFoundException(id);
    }
    return product;
  }

  @override
  Future<void> setActive(int id, {required bool active}) async {
    final updated = await (_db.update(_db.products)..where((t) => t.id.equals(id)))
        .write(db.ProductsCompanion(active: drift.Value(active)));
    if (updated == 0) {
      throw ProductByIdNotFoundException(id);
    }
  }

  @override
  Future<void> delete(int id) async {
    if (await hasMovements(id)) {
      throw const ProductHasMovementsException();
    }
    final deleted =
        await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
    if (deleted == 0) {
      throw ProductByIdNotFoundException(id);
    }
  }

  @override
  Future<bool> hasMovements(int id) async {
    final countExp = _db.movements.id.count();
    final query = _db.selectOnly(_db.movements)
      ..addColumns([countExp])
      ..where(_db.movements.productId.equals(id));
    final row = await query.getSingle();
    return (row.read(countExp) ?? 0) > 0;
  }

  drift.SimpleSelectStatement<db.$ProductsTable, db.Product> _activeQuery({
    required bool includeInactive,
  }) {
    final query = _db.select(_db.products)
      ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]);
    if (!includeInactive) {
      query.where((t) => t.active.equals(true));
    }
    return query;
  }

  List<Product> _toDomainList(List<db.Product> rows) =>
      rows.map(ProductMapper.toDomain).toList(growable: false);
}
