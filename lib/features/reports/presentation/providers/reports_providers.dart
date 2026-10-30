import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/repositories/movement_repository.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/file_inventory_export_repository.dart';
import '../../domain/entities/inventory_summary.dart';
import '../../domain/repositories/inventory_export_repository.dart';
import '../../domain/usecases/build_inventory_csv.dart';
import '../../domain/usecases/inventory_reporting.dart';

final inventoryExportRepositoryProvider = Provider<InventoryExportRepository>(
  (ref) => const FileInventoryExportRepository(),
);

final computeInventorySummaryProvider =
    Provider<ComputeInventorySummaryUseCase>((ref) {
  return ComputeInventorySummaryUseCase(ref.watch(productRepositoryProvider));
});

final stockAlertsProvider = Provider<GetStockAlertsUseCase>((ref) {
  return GetStockAlertsUseCase(ref.watch(productRepositoryProvider));
});

final categoryLookupProvider = Provider<CategoryLookup>((ref) {
  return CategoryLookup(ref.watch(categoryRepositoryProvider));
});

final buildInventoryCsvProvider = Provider<BuildInventoryCsvUseCase>((ref) {
  return BuildInventoryCsvUseCase(
    products: ref.watch(productRepositoryProvider),
    categories: ref.watch(categoryRepositoryProvider),
  );
});

/// Dashboard figures, refreshed on every stock change.
final inventorySummaryProvider = FutureProvider<InventorySummary>((ref) async {
  ref.watch(productStockRevisionProvider);
  ref.watch(movementHistoryProvider);
  return ref.watch(computeInventorySummaryProvider).call();
});

/// Low stock alerts shown on the dashboard.
final stockAlertsListProvider = FutureProvider<List<StockAlert>>((ref) async {
  ref.watch(productStockRevisionProvider);
  return ref.watch(stockAlertsProvider).call();
});

/// Category names by identifier, for display in lists and history.
final categoryNamesProvider = FutureProvider<Map<int, String>>((ref) async {
  final lookup = await ref.watch(categoryLookupProvider).call();
  return lookup;
});

/// Reads the ledger from the database, honouring the active filter.
final detailedMovementsProvider =
    FutureProvider<List<MovementWithProduct>>((ref) async {
  final filter = ref.watch(movementFilterProvider);
  return ref.watch(movementQueriesProvider).detailed(filter: filter);
});
