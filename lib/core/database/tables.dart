import 'package:drift/drift.dart';

/// Product grouping.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80).unique()();
}

/// Inventory items. `currentStock` is derived from movements, never typed in
/// directly by the user.
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 1, max: 40).unique()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  RealColumn get purchasePrice => real()();
  RealColumn get salePrice => real()();
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
  IntColumn get minimumStock => integer().withDefault(const Constant(0))();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Append only ledger. Every stock change is one row here.
class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();

  /// One of `entrada`, `salida`, `ajuste`.
  TextColumn get type => text().withLength(min: 1, max: 20)();
  IntColumn get quantity => integer()();
  IntColumn get previousStock => integer()();
  IntColumn get resultingStock => integer()();
  TextColumn get reason => text().withLength(min: 1, max: 200)();
  TextColumn get responsible => text().withLength(min: 1, max: 80)();

  /// Stored as `recorded_at`: the name `dateTime` would shadow the drift
  /// `dateTime()` column builder inside this class.
  DateTimeColumn get recordedAt => dateTime()();

  @override
  List<String> get customConstraints => const <String>[
        'CHECK (quantity >= 0)',
        'CHECK (resulting_stock >= 0)',
      ];
}

/// Single row holding the default responsible name.
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get responsibleName => text().withLength(min: 1, max: 80)();
}
