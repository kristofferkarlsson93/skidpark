import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../common/database/models/exported_glide_test.dart';

class GlideTestExportService {
  static Future<void> exportAndShare(ExportedGlideTest data) async {
    final jsonMap = data.toJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);

    final fileName = _generateFileName(data.test.title, data.test.createdAt);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(jsonString);

    final shareParams = ShareParams(
      subject: 'Exporterat glidtest - ${data.test.title}',
      files: [XFile(file.path)],
    );
    await SharePlus.instance.share(shareParams);
  }

  static String _generateFileName(String title, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final safeTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
    final formattedTitle = safeTitle.replaceAll(' ', '_');

    return 'Glidtest_${formattedTitle}_$dateStr.json';
  }
}
