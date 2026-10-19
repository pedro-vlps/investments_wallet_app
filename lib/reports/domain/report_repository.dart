import 'dart:typed_data';

import 'report_document.dart';
import 'report_trade.dart';

abstract interface class ReportRepository {
  Future<List<StoredReport>> listReports();
  Future<List<ReportTrade>> listTrades();
  Future<void> importReport({
    required String name,
    required Uint8List bytes,
    required ParsedReport report,
  });
}
