import 'dart:typed_data';

import 'report_document.dart';

abstract interface class ReportRepository {
  Future<List<StoredReport>> listReports();
  Future<void> importReport({
    required String name,
    required Uint8List bytes,
    required ParsedReport report,
  });
}
