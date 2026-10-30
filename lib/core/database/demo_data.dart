import 'package:drift/drift.dart' as drift;

import 'app_database.dart' as db;
import '../../features/inventory/domain/entities/movement.dart';
import 'mappers.dart';


/// Seed values for a fresh installation.
class DemoProduct {
  const DemoProduct({
    required this.code,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.initialStock,
    required this.minimumStock,
    required this.description,
  });

  final String code;
  final String name;
  final String category;
  final double purchasePrice;
  final double salePrice;
  final int initialStock;
  final int minimumStock;
  final String description;
}

/// Three categories and fifteen products, with coherent opening balances.
///
/// Every initial stock becomes a movement of type `entrada`, never a direct
/// column value, so the ledger explains the whole stock on hand.
class DemoData {
  static const String defaultResponsible = 'Administrador';

  static const List<String> categories = <String>[
    'Abarrotes',
    'Bebidas',
    'Aseo',
  ];

  static const List<DemoProduct> products = <DemoProduct>[
    DemoProduct(
      code: 'AB-001',
      name: 'Arroz blanco 1 kg',
      category: 'Abarrotes',
      purchasePrice: 3200,
      salePrice: 4500,
      initialStock: 40,
      minimumStock: 10,
      description: 'Arroz de grano largo, bolsa de 1 kg.',
    ),
    DemoProduct(
      code: 'AB-002',
      name: 'Frijol rojo 500 g',
      category: 'Abarrotes',
      purchasePrice: 4100,
      salePrice: 5600,
      initialStock: 30,
      minimumStock: 8,
      description: 'Frijol rojo seleccionado, bolsa de 500 g.',
    ),
    DemoProduct(
      code: 'AB-003',
      name: 'Azucar refinada 1 kg',
      category: 'Abarrotes',
      purchasePrice: 3800,
      salePrice: 5000,
      initialStock: 25,
      minimumStock: 10,
      description: 'Azucar refinada blanca, bolsa de 1 kg.',
    ),
    DemoProduct(
      code: 'AB-004',
      name: 'Aceite vegetal 1 L',
      category: 'Abarrotes',
      purchasePrice: 8900,
      salePrice: 11500,
      initialStock: 18,
      minimumStock: 6,
      description: 'Aceite vegetal comestible, botella de 1 litro.',
    ),
    DemoProduct(
      code: 'AB-005',
      name: 'Pasta larga 500 g',
      category: 'Abarrotes',
      purchasePrice: 2900,
      salePrice: 3900,
      initialStock: 35,
      minimumStock: 12,
      description: 'Pasta de trigo larga, paquete de 500 g.',
    ),
    DemoProduct(
      code: 'AB-006',
      name: 'Sal refinada 1 kg',
      category: 'Abarrotes',
      purchasePrice: 1500,
      salePrice: 2400,
      initialStock: 22,
      minimumStock: 10,
      description: 'Sal refinada yodada, bolsa de 1 kg.',
    ),
    DemoProduct(
      code: 'BE-001',
      name: 'Agua potable 600 ml',
      category: 'Bebidas',
      purchasePrice: 1200,
      salePrice: 2000,
      initialStock: 60,
      minimumStock: 24,
      description: 'Agua potable embotellada, 600 ml.',
    ),
    DemoProduct(
      code: 'BE-002',
      name: 'Gaseosa cola 1.5 L',
      category: 'Bebidas',
      purchasePrice: 4200,
      salePrice: 6000,
      initialStock: 32,
      minimumStock: 12,
      description: 'Bebida gaseosa sabor cola, botella de 1.5 litros.',
    ),
    DemoProduct(
      code: 'BE-003',
      name: 'Jugo de naranja 1 L',
      category: 'Bebidas',
      purchasePrice: 5600,
      salePrice: 7800,
      initialStock: 20,
      minimumStock: 8,
      description: 'Jugo pasteurizado de naranja, caja de 1 litro.',
    ),
    DemoProduct(
      code: 'BE-004',
      name: 'Cafe molido 250 g',
      category: 'Bebidas',
      purchasePrice: 9800,
      salePrice: 13200,
      initialStock: 15,
      minimumStock: 5,
      description: 'Cafe tostado y molido, paquete de 250 g.',
    ),
    DemoProduct(
      code: 'BE-005',
      name: 'Leche entera 1 L',
      category: 'Bebidas',
      purchasePrice: 4300,
      salePrice: 5900,
      initialStock: 28,
      minimumStock: 10,
      description: 'Leche entera ultrapasteurizada, caja de 1 litro.',
    ),
    DemoProduct(
      code: 'AS-001',
      name: 'Jabon de bano 110 g',
      category: 'Aseo',
      purchasePrice: 2400,
      salePrice: 3500,
      initialStock: 26,
      minimumStock: 10,
      description: 'Jabon de bano en barra, 110 g.',
    ),
    DemoProduct(
      code: 'AS-002',
      name: 'Detergente en polvo 900 g',
      category: 'Aseo',
      purchasePrice: 8700,
      salePrice: 11900,
      initialStock: 14,
      minimumStock: 6,
      description: 'Detergente en polvo para ropa, bolsa de 900 g.',
    ),
    DemoProduct(
      code: 'AS-003',
      name: 'Papel higienico x 4',
      category: 'Aseo',
      purchasePrice: 5200,
      salePrice: 7200,
      initialStock: 24,
      minimumStock: 12,
      description: 'Papel higienico doble hoja, paquete de 4 rollos.',
    ),
    DemoProduct(
      code: 'AS-004',
      name: 'Limpiador multiusos 1 L',
      category: 'Aseo',
      purchasePrice: 6100,
      salePrice: 8400,
      initialStock: 9,
      minimumStock: 10,
      description: 'Limpiador liquido multiusos, botella de 1 litro.',
    ),
  ];
}

/// Inserts the demo catalogue when the database has no products yet.
///
/// Returns `true` when the seed ran, so the caller can report it.
Future<bool> seedDemoData(db.AppDatabase database) async {
  final existing = await database.select(database.products).get();
  if (existing.isNotEmpty) {
    return false;
  }

  final now = DateTime.now();
  final openingDate = DateTime(now.year, now.month, now.day, 8);

  await database.transaction(() async {
    final categoryIds = <String, int>{};
    for (final name in DemoData.categories) {
      final id = await database
          .into(database.categories)
          .insert(db.CategoriesCompanion.insert(name: name));
      categoryIds[name] = id;
    }

    for (var index = 0; index < DemoData.products.length; index++) {
      final demo = DemoData.products[index];
      final productId = await database.into(database.products).insert(
            CompanionFactory.productInsert(
              code: demo.code,
              name: demo.name,
              description: demo.description,
              categoryId: categoryIds[demo.category],
              purchasePrice: demo.purchasePrice,
              salePrice: demo.salePrice,
              minimumStock: demo.minimumStock,
            ),
          );

      final movement = Movement(
        productId: productId,
        type: MovementType.entry,
        quantity: demo.initialStock,
        previousStock: 0,
        resultingStock: demo.initialStock,
        reason: 'Existencia inicial de ${demo.initialStock} unidades',
        responsible: DemoData.defaultResponsible,
        dateTime: openingDate.add(Duration(minutes: index)),
      );

      await database
          .into(database.movements)
          .insert(CompanionFactory.movementInsert(movement));
      await (database.update(database.products)..where((t) => t.id.equals(productId)))
          .write(db.ProductsCompanion(currentStock: drift.Value(demo.initialStock)));
    }

    await database.into(database.profiles).insert(
          db.ProfilesCompanion.insert(
            responsibleName: DemoData.defaultResponsible,
          ),
        );
  });

  return true;
}
