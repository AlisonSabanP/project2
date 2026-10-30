import '../../../../core/error/domain_exception.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Reads used by the product screens, the scanner and the reports.
class ProductQueries {
  const ProductQueries(this._products);

  final ProductRepository _products;

  Stream<List<Product>> watchAll({bool includeInactive = false}) =>
      _products.watchAll(includeInactive: includeInactive);

  Future<List<Product>> all({bool includeInactive = false}) =>
      _products.findAll(includeInactive: includeInactive);

  Future<Product> byId(int id) async {
    final product = await _products.findById(id);
    if (product == null) {
      throw ProductByIdNotFoundException(id);
    }
    return product;
  }

  /// Scanner lookup. Returns `null` when the code is unknown so the UI can
  /// show the "codigo no registrado" state.
  Future<Product?> byCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return Future.value(null);
    }
    return _products.findByCode(normalized);
  }

  Future<List<Product>> search(String term, {bool includeInactive = false}) =>
      _products.search(term, includeInactive: includeInactive);

  Future<List<Product>> lowStock({bool includeInactive = false}) =>
      _products.findLowStock(includeInactive: includeInactive);

  Future<int> count({bool includeInactive = false}) =>
      _products.countAll(includeInactive: includeInactive);
}
