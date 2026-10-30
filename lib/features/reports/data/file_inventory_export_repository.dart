import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/repositories/inventory_export_repository.dart';

/// Writes CSV exports into the application documents directory.
///
/// Uses `path_provider`, so no platform specific storage permissions are
/// required on Android.
class FileInventoryExportRepository implements InventoryExportRepository {
  const FileInventoryExportRepository();

  static const String exportDirectoryName = 'exportaciones';

  @override
  Future<String> writeExport({
    required String fileName,
    required String content,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, exportDirectoryName));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(content, flush: true);
    return file.path;
  }
}
