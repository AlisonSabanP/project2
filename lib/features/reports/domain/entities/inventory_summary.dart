import '../../../products/domain/entities/product.dart';

/// Aggregated figures shown on the dashboard.
class InventorySummary {
  const InventorySummary({
    required this.productCount,
    required this.activeProductCount,
    required this.totalUnits,
    required this.purchaseValue,
    required this.saleValue,
    required this.lowStockProducts,
  });

  final int productCount;
  final int activeProductCount;
  final int totalUnits;

  /// Existencias x precio de compra. A simple estimate, not an accounting
  /// valuation method.
  final double purchaseValue;
  final double saleValue;
  final List<Product> lowStockProducts;

  int get lowStockCount => lowStockProducts.length;

  bool get isEmpty => productCount == 0;

  static const InventorySummary empty = InventorySummary(
    productCount: 0,
    activeProductCount: 0,
    totalUnits: 0,
    purchaseValue: 0,
    saleValue: 0,
    lowStockProducts: <Product>[],
  );
}

/// A product whose stock reached its minimum level.
class StockAlert {
  const StockAlert({required this.product, required this.missingUnits});

  final Product product;

  /// Units needed to reach the minimum stock again.
  final int missingUnits;
}
