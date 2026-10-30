import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_bodega/core/database/app_database.dart';
import 'package:inventario_bodega/core/database/demo_data.dart';
import 'package:inventario_bodega/core/error/domain_exception.dart';
import 'package:inventario_bodega/features/inventory/data/drift_movement_repository.dart';
import 'package:inventario_bodega/features/inventory/domain/entities/movement.dart';
import 'package:inventario_bodega/features/inventory/domain/entities/movement_filter.dart';
import 'package:inventario_bodega/features/inventory/domain/usecases/register_movement.dart';
import 'package:inventario_bodega/features/products/data/drift_category_repository.dart';
import 'package:inventario_bodega/features/products/data/drift_product_repository.dart';
import 'package:inventario_bodega/features/products/domain/entities/product_draft.dart';
import 'package:inventario_bodega/features/products/domain/usecases/create_product.dart';
import 'package:inventario_bodega/features/products/domain/usecases/manage_product_state.dart';
import 'package:inventario_bodega/features/products/domain/usecases/product_queries.dart';
import 'package:inventario_bodega/features/products/domain/usecases/update_product.dart';
import 'package:inventario_bodega/features/reports/domain/usecases/build_inventory_csv.dart';
import 'package:inventario_bodega/features/reports/domain/usecases/inventory_reporting.dart';
import 'package:inventario_bodega/features/scanner/domain/usecases/resolve_scanned_code.dart';
import 'package:inventario_bodega/features/settings/data/drift_profile_repository.dart';
import 'package:inventario_bodega/features/settings/domain/usecases/profile_usecases.dart';

/// Exercises the whole acceptance flow against a real SQLite database opened
/// in memory: products, movements, stock rules, reports and persistence.
void main() {
  late AppDatabase database;
  late DriftProductRepository products;
  late DriftCategoryRepository categories;
  late DriftMovementRepository movements;
  late RegisterMovementUseCase registerMovement;
  late CreateProductUseCase createProduct;
  late ProductQueries queries;

  setUp(() {
    database = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    products = DriftProductRepository(database);
    categories = DriftCategoryRepository(database);
    movements = DriftMovementRepository(database);
    queries = ProductQueries(products);
    createProduct = CreateProductUseCase(products);
    registerMovement = RegisterMovementUseCase(
      products: products,
      movements: movements,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('crear un producto con stock inicial genera un movimiento de entrada',
      () async {
    final product = await createProduct(
      draft: const ProductDraft(
        code: 'TEST-001',
        name: 'Producto de prueba',
        purchasePrice: 1000,
        salePrice: 1500,
        minimumStock: 5,
      ),
      initialStock: 20,
      responsible: 'Administrador',
    );

    expect(product.currentStock, 20);

    final ledger = await movements.findAll();
    expect(ledger, hasLength(1));
    expect(ledger.single.type, MovementType.entry);
    expect(ledger.single.previousStock, 0);
    expect(ledger.single.resultingStock, 20);
    expect(ledger.single.responsible, 'Administrador');
  });

  test('el codigo de producto es unico', () async {
    await createProduct(
      draft: const ProductDraft(
        code: 'DUP-001',
        name: 'Primero',
        purchasePrice: 1000,
        salePrice: 1500,
        minimumStock: 1,
      ),
      responsible: 'Administrador',
    );

    expect(
      () => createProduct(
        draft: const ProductDraft(
          code: 'dup-001',
          name: 'Segundo',
          purchasePrice: 1000,
          salePrice: 1500,
          minimumStock: 1,
        ),
        responsible: 'Administrador',
      ),
      throwsA(isA<DuplicateProductCodeException>()),
    );
  });

  test('flujo de aceptacion completo', () async {
    // Paso 1: producto con stock minimo de 5 unidades.
    final product = await createProduct(
      draft: const ProductDraft(
        code: 'FLOW-001',
        name: 'Producto del flujo',
        purchasePrice: 2000,
        salePrice: 3000,
        minimumStock: 5,
      ),
      responsible: 'Administrador',
    );
    final productId = product.id!;
    expect(product.currentStock, 0);

    // Paso 2: entrada de 20 unidades.
    await registerMovement(
      productId: productId,
      type: MovementType.entry,
      quantity: 20,
      reason: 'Compra',
      responsible: 'Administrador',
    );
    expect((await queries.byId(productId)).currentStock, 20);

    // Paso 3: salida de 16 unidades.
    await registerMovement(
      productId: productId,
      type: MovementType.exit,
      quantity: 16,
      reason: 'Venta',
      responsible: 'Administrador',
    );

    // Paso 4: quedan 4 unidades y aparece la alerta de stock bajo.
    final afterExit = await queries.byId(productId);
    expect(afterExit.currentStock, 4);
    expect(afterExit.isLowStock, isTrue);

    final alerts = await GetStockAlertsUseCase(products).call();
    expect(alerts.map((alert) => alert.product.code), contains('FLOW-001'));
    expect(
      alerts.firstWhere((a) => a.product.code == 'FLOW-001').missingUnits,
      1,
    );

    // Paso 5: retirar 5 unidades con solo 4 disponibles debe fallar.
    expect(
      () => registerMovement(
        productId: productId,
        type: MovementType.exit,
        quantity: 5,
        reason: 'Venta',
        responsible: 'Administrador',
      ),
      throwsA(isA<InsufficientStockException>()),
    );

    // El fallo no altera el stock ni deja movimientos parciales.
    expect((await queries.byId(productId)).currentStock, 4);
    expect(await movements.countByProduct(productId), 2);

    // Paso 6: ajuste a 3 unidades con justificacion.
    await registerMovement(
      productId: productId,
      type: MovementType.adjustment,
      quantity: 3,
      reason: 'Conteo fisico con diferencia',
      responsible: 'Administrador',
    );
    expect((await queries.byId(productId)).currentStock, 3);

    // Paso 7: el ajuste sin justificacion se rechaza.
    expect(
      () => registerMovement(
        productId: productId,
        type: MovementType.adjustment,
        quantity: 1,
        reason: '  ',
        responsible: 'Administrador',
      ),
      throwsA(isA<MissingJustificationException>()),
    );

    // Paso 8: historial filtrable.
    final history = await movements.findAll(
      filter: MovementFilter(productId: productId),
    );
    expect(history, hasLength(3));
    expect(history.first.type, MovementType.adjustment);

    final entriesOnly = await movements.findAll(
      filter: const MovementFilter(type: MovementType.entry),
    );
    expect(entriesOnly, hasLength(1));

    // Paso 9: exportacion a CSV.
    final csv = await BuildInventoryCsvUseCase(
      products: products,
      categories: categories,
    ).call();
    expect(csv, contains('FLOW-001'));
    expect(csv, contains('stock_actual'));
    expect(csv.split('\n').first, contains('codigo'));

    // Paso 10: valor del inventario = existencias x precio de compra.
    final summary = await ComputeInventorySummaryUseCase(products).call();
    expect(summary.purchaseValue, 3 * 2000);
    expect(summary.totalUnits, 3);
  });

  test('un movimiento confirmado no se puede editar ni eliminar', () async {
    final product = await createProduct(
      draft: const ProductDraft(
        code: 'IMM-001',
        name: 'Inmutable',
        purchasePrice: 1000,
        salePrice: 1500,
        minimumStock: 1,
      ),
      initialStock: 10,
      responsible: 'Administrador',
    );

    // La correccion se hace con un nuevo movimiento, nunca reescribiendo.
    await registerMovement(
      productId: product.id!,
      type: MovementType.adjustment,
      quantity: 8,
      reason: 'Correccion de registro',
      responsible: 'Administrador',
    );

    expect((await queries.byId(product.id!)).currentStock, 8);
    expect(await movements.countByProduct(product.id!), 2);
  });

  test('un producto con movimientos solo se desactiva', () async {
    final product = await createProduct(
      draft: const ProductDraft(
        code: 'DEL-001',
        name: 'Con historial',
        purchasePrice: 1000,
        salePrice: 1500,
        minimumStock: 1,
      ),
      initialStock: 5,
      responsible: 'Administrador',
    );

    final delete = DeleteProductUseCase(products);
    expect(
      () => delete(product.id!),
      throwsA(isA<ProductHasMovementsException>()),
    );

    await SetProductActiveUseCase(products).call(
      id: product.id!,
      active: false,
    );
    expect((await queries.byId(product.id!)).active, isFalse);
    expect(await queries.all(), isEmpty);
    expect(await queries.all(includeInactive: true), hasLength(1));
  });

  test('el escaner resuelve codigos de barras y QR y avisa de los no registrados',
      () async {
    await createProduct(
      draft: const ProductDraft(
        code: 'SCAN-001',
        name: 'Escaneable',
        purchasePrice: 1000,
        salePrice: 1500,
        minimumStock: 1,
      ),
      initialStock: 7,
      responsible: 'Administrador',
    );

    final resolve = ResolveScannedCodeUseCase(queries);

    // El codigo de barras Code 128 y el QR codifican el mismo valor.
    final fromBarcode = await resolve('scan-001');
    expect(fromBarcode.isRegistered, isTrue);
    expect(fromBarcode.product!.currentStock, 7);

    final fromQr = await resolve('SCAN-001');
    expect(fromQr.isRegistered, isTrue);

    final unknown = await resolve('NO-EXISTE');
    expect(unknown.isRegistered, isFalse);
    expect(unknown.code, 'NO-EXISTE');
  });

  test('los datos persisten al cerrar y reabrir la base de datos', () async {
    final directory = await Directory.systemTemp.createTemp('inventario_test');
    final file = File(p.join(directory.path, 'inventario.sqlite'));

    final first = AppDatabase(DatabaseConnection(NativeDatabase(file)));
    await seedDemoData(first);
    final before = await DriftProductRepository(first).countAll(
      includeInactive: true,
    );
    final movementsBefore =
        await DriftMovementRepository(first).findAll();
    await first.close();

    final second = AppDatabase(DatabaseConnection(NativeDatabase(file)));
    final after = await DriftProductRepository(second).countAll(
      includeInactive: true,
    );
    final movementsAfter = await DriftMovementRepository(second).findAll();
    await second.close();

    expect(after, before);
    expect(movementsAfter, hasLength(movementsBefore.length));

    await directory.delete(recursive: true);
  });

  test('la carga de demostracion incluye 15 productos y 3 categorias',
      () async {
    final seeded = await seedDemoData(database);
    expect(seeded, isTrue);

    final productCount = await products.countAll(includeInactive: true);
    expect(productCount, 15);

    final categoryList = await categories.findAll();
    expect(categoryList, hasLength(3));
    expect(
      categoryList.map((category) => category.name),
      containsAll(<String>['Abarrotes', 'Bebidas', 'Aseo']),
    );

    // Cada producto tiene su movimiento de entrada inicial.
    final ledger = await movements.findAll();
    expect(ledger, hasLength(15));
    expect(ledger.every((movement) => movement.type == MovementType.entry), isTrue);

    // Sembrar dos veces no duplica datos.
    expect(await seedDemoData(database), isFalse);
    expect(await products.countAll(includeInactive: true), 15);
  });

  test('el perfil local guarda el responsable de los movimientos', () async {
    final repository = DriftProfileRepository(database);
    final save = SaveProfileUseCase(repository);
    final load = LoadProfileUseCase(repository);

    expect((await load()).isEmpty, isTrue);

    await save('Maria Perez');
    expect((await load()).responsibleName, 'Maria Perez');

    await save('Juan Gomez');
    expect((await load()).responsibleName, 'Juan Gomez');

    expect(() => save('   '), throwsA(isA<ValidationException>()));
  });

  test('actualizar un producto no modifica su stock', () async {
    final product = await createProduct(
      draft: const ProductDraft(
        code: 'UPD-001',
        name: 'Original',
        purchasePrice: 1000,
        salePrice: 1500,
        minimumStock: 1,
      ),
      initialStock: 9,
      responsible: 'Administrador',
    );

    final update = UpdateProductUseCase(products);
    final updated = await update(
      id: product.id!,
      draft: const ProductDraft(
        code: 'UPD-001',
        name: 'Renombrado',
        purchasePrice: 1200,
        salePrice: 1800,
        minimumStock: 3,
      ),
    );

    expect(updated.name, 'Renombrado');
    expect(updated.currentStock, 9);
    expect(updated.minimumStock, 3);
  });
}
