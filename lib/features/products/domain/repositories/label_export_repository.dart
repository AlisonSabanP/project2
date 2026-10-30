/// Saves and shares the printable label of a product.
abstract interface class LabelExportRepository {
  /// Persists [pngBytes] and returns the absolute file path.
  Future<String> saveLabel({
    required String productCode,
    required List<int> pngBytes,
  });

  /// Opens the platform share sheet for the file at [path].
  Future<void> shareLabel({required String path, required String title});
}
