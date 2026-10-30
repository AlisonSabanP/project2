import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/domain/usecases/product_queries.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/usecases/resolve_scanned_code.dart';

final resolveScannedCodeProvider = Provider<ResolveScannedCodeUseCase>((ref) {
  return ResolveScannedCodeUseCase(
    ProductQueries(ref.watch(productRepositoryProvider)),
  );
});

/// Manual code or name search shown when the camera is unavailable.
final manualSearchTermProvider =
    NotifierProvider<ManualSearchTermNotifier, String>(
  ManualSearchTermNotifier.new,
);

class ManualSearchTermNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String term) => state = term;
}
