import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart' as db;
import '../../../core/error/domain_exception.dart';
import '../domain/entities/category.dart';
import '../domain/repositories/category_repository.dart';
import '../../../core/database/mappers.dart';

/// Drift backed implementation of [CategoryRepository].
class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<Category>> watchAll() => _orderedQuery().watch().map(_toDomain);

  @override
  Future<List<Category>> findAll() async => _toDomain(await _orderedQuery().get());

  @override
  Future<Category?> findById(int id) async {
    final row = await (_db.select(_db.categories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : ProductMapper.categoryToDomain(row);
  }

  @override
  Future<Category> create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException(
        'El nombre de la categoria es obligatorio.',
      );
    }
    final existing = await (_db.select(_db.categories)
          ..where((t) => t.name.upper().equals(trimmed.toUpperCase())))
        .getSingleOrNull();
    if (existing != null) {
      throw ValidationException('La categoria "$trimmed" ya existe.');
    }
    final id = await _db
        .into(_db.categories)
        .insert(db.CategoriesCompanion.insert(name: trimmed));
    return Category(id: id, name: trimmed);
  }

  @override
  Future<void> rename(int id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException(
        'El nombre de la categoria es obligatorio.',
      );
    }
    final updated =
        await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      db.CategoriesCompanion(name: drift.Value(trimmed)),
    );
    if (updated == 0) {
      throw ValidationException('No existe la categoria con identificador $id.');
    }
  }

  @override
  Future<void> delete(int id) async {
    final countExp = _db.products.id.count();
    final query = _db.selectOnly(_db.products)
      ..addColumns([countExp])
      ..where(_db.products.categoryId.equals(id));
    final row = await query.getSingle();
    if ((row.read(countExp) ?? 0) > 0) {
      throw const ValidationException(
        'La categoria tiene productos asociados; no puede eliminarse.',
      );
    }
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }

  drift.SimpleSelectStatement<db.$CategoriesTable, db.Category> _orderedQuery() {
    return _db.select(_db.categories)
      ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]);
  }

  List<Category> _toDomain(List<db.Category> rows) =>
      rows.map(ProductMapper.categoryToDomain).toList(growable: false);
}
