import '../entities/product.dart';
import '../entities/product_draft.dart';

/// Persistence contract for products.
///
/// Implementations live in the data layer. Methods that change stock
/// ([create] with an initial stock) must persist the product and its movement
/// inside a single database transaction.
abstract interface class ProductRepository {
  /// Reactive listing used by the UI.
  Stream<List<Product>> watchAll({bool includeInactive = false});

  Future<List<Product>> findAll({bool includeInactive = false});

  Future<Product?> findById(int id);

  /// Lookup by the unique business code, used by the scanner.
  Future<Product?> findByCode(String code);

  /// Matches the code or the name, case insensitive.
  Future<List<Product>> search(String term, {bool includeInactive = false});

  Future<List<Product>> findLowStock({bool includeInactive = false});

  Future<int> countAll({bool includeInactive = false});

  Future<bool> isCodeTaken(String code, {int? exceptProductId});

  /// Creates the product and, when [initialStock] is greater than zero, the
  /// matching entry movement in the same transaction.
  Future<Product> create(
    ProductDraft draft, {
    int initialStock = 0,
    String responsible = '',
  });

  /// Updates the descriptive fields. Stock is never written here.
  Future<Product> update(int id, ProductDraft draft);

  Future<void> setActive(int id, {required bool active});

  /// Physical deletion. Implementations must reject it when the product has
  /// movements registered.
  Future<void> delete(int id);

  Future<bool> hasMovements(int id);
}
