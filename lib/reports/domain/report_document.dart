import 'report_trade.dart';

class ReportIssue {
  const ReportIssue(this.location, this.reason);
  final String location;
  final String reason;
}

class ParsedReport {
  const ParsedReport({
    required this.trades,
    required this.issues,
    required this.layouts,
  });
  final List<ReportTrade> trades;
  final List<ReportIssue> issues;
  final Set<String> layouts;
}

class ReportAssetSummary {
  const ReportAssetSummary({
    required this.symbol,
    required this.name,
    required this.boughtMicros,
    required this.soldMicros,
    required this.newTrades,
    this.settlementTrades = 0,
  });
  final String symbol;
  final String name;
  final int boughtMicros;
  final int soldMicros;
  final int newTrades;
  final int settlementTrades;
}

class StoredReport {
  const StoredReport({
    required this.id,
    required this.name,
    required this.importedAt,
    required this.relativePath,
    required this.assets,
    required this.issues,
    required this.duplicateTrades,
  });
  final String id;
  final String name;
  final DateTime importedAt;
  final String relativePath;
  final List<ReportAssetSummary> assets;
  final List<ReportIssue> issues;
  final int duplicateTrades;
}
