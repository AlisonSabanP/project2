import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/domain_exception.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/drift_category_repository.dart';
import '../../data/drift_product_repository.dart';
import '../../data/share_label_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_draft.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/label_export_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/create_product.dart';
import '../../domain/usecases/manage_product_state.dart';
import '../../domain/usecases/product_queries.dart';
import '../../domain/usecases/update_product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return DriftProductRepository(ref.watch(databaseProvider));
});

/// Persists and shares the printable label of a product.
final labelExportRepositoryProvider = Provider<LabelExportRepository>((ref) {
  return const ShareLabelRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return DriftCategoryRepository(ref.watch(databaseProvider));
});

final productQueriesProvider = Provider<ProductQueries>((ref) {
  return ProductQueries(ref.watch(productRepositoryProvider));
});

final createProductProvider = Provider<CreateProductUseCase>((ref) {
  return CreateProductUseCase(ref.watch(productRepositoryProvider));
});

final updateProductProvider = Provider<UpdateProductUseCase>((ref) {
  return UpdateProductUseCase(ref.watch(productRepositoryProvider));
});

final setProductActiveProvider = Provider<SetProductActiveUseCase>((ref) {
  return SetProductActiveUseCase(ref.watch(productRepositoryProvider));
});

final deleteProductProvider = Provider<DeleteProductUseCase>((ref) {
  return DeleteProductUseCase(ref.watch(productRepositoryProvider));
});

/// Text typed into the product search field.
final productSearchProvider = NotifierProvider<ProductSearchNotifier, String>(
  ProductSearchNotifier.new,
);

class ProductSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String term) => state = term;

  void clear() => state = '';
}

/// Category filter applied to the product list.
final productCategoryFilterProvider =
    NotifierProvider<ProductCategoryFilterNotifier, int?>(
  ProductCategoryFilterNotifier.new,
);

class ProductCategoryFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? categoryId) => state = categoryId;
}

/// Whether inactive products are listed.
final showInactiveProductsProvider =
    NotifierProvider<ShowInactiveNotifier, bool>(ShowInactiveNotifier.new);

class ShowInactiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// Live product list honouring the search term and the filters.
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final queries = ref.watch(productQueriesProvider);
  final term = ref.watch(productSearchProvider);
  final categoryId = ref.watch(productCategoryFilterProvider);
  final includeInactive = ref.watch(showInactiveProductsProvider);

  final products = term.trim().isEmpty
      ? await queries.all(includeInactive: includeInactive)
      : await queries.search(term, includeInactive: includeInactive);

  if (categoryId == null) {
    return products;
  }
  return products.where((product) => product.categoryId == categoryId).toList();
});

/// Live list of categories used by filters and forms.
final categoryListProvider = StreamProvider((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

/// Single product, refreshed whenever the ledger changes its stock.
final productDetailProvider = FutureProvider.family<Product, int>((ref, id) async {
  ref.watch(productStockRevisionProvider);
  return ref.watch(productQueriesProvider).byId(id);
});

/// Counter bumped after every movement so dependent providers refresh.
final productStockRevisionProvider =
    NotifierProvider<StockRevisionNotifier, int>(StockRevisionNotifier.new);

class StockRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

/// Saves the product form, creating or updating according to [productId].
///
/// Returns the persisted product so the caller can navigate to its detail.
final saveProductProvider = Provider<SaveProduct>((ref) {
  return SaveProduct(ref);
});

class SaveProduct {
  const SaveProduct(this._ref);

  final Ref _ref;

  Future<Product> call({
    int? productId,
    required ProductDraft draft,
    int initialStock = 0,
    required String responsible,
  }) async {
    final result = productId == null
        ? await _ref.read(createProductProvider).call(
              draft: draft,
              initialStock: initialStock,
              responsible: responsible,
            )
        : await _ref.read(updateProductProvider).call(
              id: productId,
              draft: draft,
            );
    _ref.read(productStockRevisionProvider.notifier).bump();
    return result;
  }
}

/// Turns a domain failure into a message ready for a snackbar.
String describeFailure(Object error) {
  if (error is DomainException) {
    return error.message;
  }
  return 'Ocurrio un error inesperado: $error';
}
