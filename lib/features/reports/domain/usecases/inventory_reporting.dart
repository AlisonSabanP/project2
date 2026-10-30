import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/category_repository.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../entities/inventory_summary.dart';

/// Computes the dashboard figures and the low stock alerts.
///
/// Inventory value is a plain estimate: stock multiplied by the purchase
/// price, with no accounting method behind it.
class ComputeInventorySummaryUseCase {
  const ComputeInventorySummaryUseCase(this._products);

  final ProductRepository _products;

  Future<InventorySummary> call() async {
    final products = await _products.findAll();
    if (products.isEmpty) {
      return InventorySummary.empty;
    }

    var totalUnits = 0;
    var purchaseValue = 0.0;
    var saleValue = 0.0;
    final alerts = <Product>[];

    for (final product in products) {
      totalUnits += product.currentStock;
      purchaseValue += product.stockPurchaseValue;
      saleValue += product.stockSaleValue;
      if (product.isLowStock) {
        alerts.add(product);
      }
    }

    alerts.sort((a, b) => a.currentStock.compareTo(b.currentStock));

    final all = await _products.findAll(includeInactive: true);

    return InventorySummary(
      productCount: all.length,
      activeProductCount: products.length,
      totalUnits: totalUnits,
      purchaseValue: purchaseValue,
      saleValue: saleValue,
      lowStockProducts: alerts,
    );
  }
}

/// Lists the products that reached or dropped below their minimum stock.
class GetStockAlertsUseCase {
  const GetStockAlertsUseCase(this._products);

  final ProductRepository _products;

  Future<List<StockAlert>> call({bool includeInactive = false}) async {
    final products = await _products.findLowStock(includeInactive: includeInactive);
    final alerts = products
        .map(
          (product) => StockAlert(
            product: product,
            missingUnits: product.minimumStock - product.currentStock,
          ),
        )
        .toList();
    alerts.sort((a, b) => a.product.currentStock.compareTo(b.product.currentStock));
    return alerts;
  }
}

/// Resolves category names for a set of products.
class CategoryLookup {
  const CategoryLookup(this._categories);

  final CategoryRepository _categories;

  Future<Map<int, String>> call() async {
    final categories = await _categories.findAll();
    return <int, String>{
      for (final Category category in categories) category.id: category.name,
    };
  }
}
