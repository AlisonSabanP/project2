import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/drift_movement_repository.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/movement_filter.dart';
import '../../domain/repositories/movement_repository.dart';
import '../../domain/usecases/movement_queries.dart';
import '../../domain/usecases/register_movement.dart';

final movementRepositoryProvider = Provider<MovementRepository>((ref) {
  return DriftMovementRepository(ref.watch(databaseProvider));
});

final movementQueriesProvider = Provider<MovementQueries>((ref) {
  return MovementQueries(ref.watch(movementRepositoryProvider));
});

final registerMovementProvider = Provider<RegisterMovementUseCase>((ref) {
  return RegisterMovementUseCase(
    products: ref.watch(productRepositoryProvider),
    movements: ref.watch(movementRepositoryProvider),
  );
});

/// Active filter of the history screen.
final movementFilterProvider =
    NotifierProvider<MovementFilterNotifier, MovementFilter>(
  MovementFilterNotifier.new,
);

class MovementFilterNotifier extends Notifier<MovementFilter> {
  @override
  MovementFilter build() => const MovementFilter();

  void setProduct(int? productId) {
    state = productId == null
        ? state.copyWith(clearProduct: true)
        : state.copyWith(productId: productId);
  }

  void setType(MovementType? type) {
    state = type == null
        ? state.copyWith(clearType: true)
        : state.copyWith(type: type);
  }

  void setRange(DateTime? from, DateTime? to) {
    state = from == null && to == null
        ? state.copyWith(clearDates: true)
        : MovementFilter(
            productId: state.productId,
            type: state.type,
            from: from,
            to: to,
          );
  }

  void clear() => state = const MovementFilter();
}

/// Filtered movement feed for the history screen.
final movementHistoryProvider = StreamProvider<List<Movement>>((ref) {
  final filter = ref.watch(movementFilterProvider);
  return ref.watch(movementQueriesProvider).watchAll(filter: filter);
});

/// Movements of a single product, newest first.
final productMovementProvider =
    StreamProvider.family<List<Movement>, int>((ref, productId) {
  return ref.watch(movementQueriesProvider).watchByProduct(productId);
});
