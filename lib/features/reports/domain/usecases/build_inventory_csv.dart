import 'package:csv/csv.dart';

import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/category_repository.dart';
import '../../../products/domain/repositories/product_repository.dart';

/// Rows exported for the inventory CSV, in a stable order.
const List<String> inventoryCsvHeader = <String>[
  'codigo',
  'nombre',
  'descripcion',
  'categoria',
  'stock_actual',
  'stock_minimo',
  'alerta_stock_bajo',
  'precio_compra',
  'precio_venta',
  'valor_compra',
  'valor_venta',
  'activo',
];

/// Builds the CSV document for the current inventory.
///
/// Uses the Excel friendly encoder settings: comma separated, quoted when
/// required and a UTF-8 BOM so accented names open correctly.
class BuildInventoryCsvUseCase {
  const BuildInventoryCsvUseCase({
    required ProductRepository products,
    required CategoryRepository categories,
  })  : _products = products,
        _categories = categories;

  final ProductRepository _products;
  final CategoryRepository _categories;

  Future<String> call({bool includeInactive = false}) async {
    final products = await _products.findAll(includeInactive: includeInactive);
    final categoryNames = <int, String>{
      for (final category in await _categories.findAll())
        category.id: category.name,
    };

    final rows = <List<dynamic>>[
      inventoryCsvHeader,
      for (final product in products)
        _row(product, categoryNames[product.categoryId] ?? 'Sin categoria'),
    ];

    return Csv(addBom: true).encode(rows);
  }

  List<dynamic> _row(Product product, String categoryName) => <dynamic>[
        product.code,
        product.name,
        product.description ?? '',
        categoryName,
        product.currentStock,
        product.minimumStock,
        product.isLowStock ? 'SI' : 'NO',
        product.purchasePrice.toStringAsFixed(2),
        product.salePrice.toStringAsFixed(2),
        product.stockPurchaseValue.toStringAsFixed(2),
        product.stockSaleValue.toStringAsFixed(2),
        product.active ? 'SI' : 'NO',
      ];
}
