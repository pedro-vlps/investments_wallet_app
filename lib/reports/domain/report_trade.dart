import '../../portfolio/domain/asset_category.dart';

enum TradeSide { buy, sell }

class ReportTrade {
  const ReportTrade({
    required this.symbol,
    required this.name,
    required this.broker,
    required this.date,
    required this.side,
    required this.quantityMicros,
    required this.priceMicros,
    required this.totalCents,
    required this.location,
    this.category,
  });

  final String symbol;
  final String name;
  final String broker;
  final DateTime date;
  final TradeSide side;
  final int quantityMicros;
  final int priceMicros;
  final int totalCents;
  final String location;
  final AssetCategory? category;

  ReportTrade classified(AssetCategory value) => ReportTrade(
    symbol: symbol,
    name: name,
    broker: broker,
    date: date,
    side: side,
    quantityMicros: quantityMicros,
    priceMicros: priceMicros,
    totalCents: totalCents,
    location: location,
    category: value,
  );
}

class ReportImportException implements Exception {
  const ReportImportException(this.message);
  final String message;
  @override
  String toString() => message;
}
