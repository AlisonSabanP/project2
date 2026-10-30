import 'package:path/path.dart' as p;

/// Writes exported files to the device storage.
///
/// Kept behind a contract so the reports feature does not depend on
/// `dart:io` details or on a concrete directory layout.
abstract interface class InventoryExportRepository {
  /// Writes [content] to a file named [fileName] and returns its absolute path.
  Future<String> writeExport({
    required String fileName,
    required String content,
  });
}

/// Builds the export file name, keeping the directory logic in one place.
String buildExportFileName(String prefix, DateTime stamp) {
  final iso = stamp.toIso8601String().split('.').first.replaceAll(':', '-');
  return p.normalize('$prefix-$iso.csv');
}
