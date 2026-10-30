import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/formatting/formatters.dart';
import '../../domain/repositories/label_export_repository.dart';

/// Saves the label PNG and hands it to the platform share sheet, so the user
/// can send it to a printer app, a chat or cloud storage.
class ShareLabelRepository implements LabelExportRepository {
  const ShareLabelRepository();

  @override
  Future<String> saveLabel({
    required String productCode,
    required List<int> pngBytes,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final labelsDir = Directory(p.join(directory.path, 'etiquetas'));
    if (!labelsDir.existsSync()) {
      await labelsDir.create(recursive: true);
    }
    final safeCode = productCode.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final fileName =
        'etiqueta-$safeCode-${Formatters.fileStamp(DateTime.now())}.png';
    final file = File(p.join(labelsDir.path, fileName));
    await file.writeAsBytes(pngBytes, flush: true);
    return file.path;
  }

  @override
  Future<void> shareLabel({required String path, required String title}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'image/png')],
        subject: title,
        text: title,
      ),
    );
  }
}
