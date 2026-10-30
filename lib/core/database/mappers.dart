import 'package:drift/drift.dart' as drift;

import 'app_database.dart' as db;
import '../../features/inventory/domain/entities/movement.dart';
import '../../features/products/domain/entities/category.dart';
import '../../features/products/domain/entities/product.dart';

/// Translation between drift rows and domain entities.
///
/// Keeping it in one file makes the storage schema the only place that knows
/// about column names.
abstract final class ProductMapper {
  static Product toDomain(db.Product row) => Product(
        id: row.id,
        code: row.code,
        name: row.name,
        description: row.description,
        categoryId: row.categoryId,
        purchasePrice: row.purchasePrice,
        salePrice: row.salePrice,
        currentStock: row.currentStock,
        minimumStock: row.minimumStock,
        photoPath: row.photoPath,
        active: row.active,
      );

  static Category categoryToDomain(db.Category row) =>
      Category(id: row.id, name: row.name);
}

abstract final class MovementMapper {
  static Movement toDomain(db.Movement row) => Movement(
        id: row.id,
        productId: row.productId,
        type: MovementType.fromName(row.type),
        quantity: row.quantity,
        previousStock: row.previousStock,
        resultingStock: row.resultingStock,
        reason: row.reason,
        responsible: row.responsible,
        dateTime: row.recordedAt,
      );

  static String typeToColumn(MovementType type) => type.name;
}

/// Builds the drift companions used by the insert and update statements.
abstract final class CompanionFactory {
  static db.ProductsCompanion productInsert({
    required String code,
    required String name,
    String? description,
    int? categoryId,
    required double purchasePrice,
    required double salePrice,
    required int minimumStock,
    String? photoPath,
    bool active = true,
  }) {
    return db.ProductsCompanion.insert(
      code: code,
      name: name,
      description: drift.Value.absentIfNull(description),
      categoryId: drift.Value.absentIfNull(categoryId),
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      minimumStock: drift.Value(minimumStock),
      photoPath: drift.Value.absentIfNull(photoPath),
      active: drift.Value(active),
    );
  }

  static db.MovementsCompanion movementInsert(Movement movement) {
    return db.MovementsCompanion.insert(
      productId: movement.productId,
      type: MovementMapper.typeToColumn(movement.type),
      quantity: movement.quantity,
      previousStock: movement.previousStock,
      resultingStock: movement.resultingStock,
      reason: movement.reason,
      responsible: movement.responsible,
      recordedAt: movement.dateTime,
    );
  }
}
