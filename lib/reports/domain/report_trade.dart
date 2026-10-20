import '../../portfolio/domain/asset_category.dart';

enum TradeSide { buy, sell }

enum ReportDateBasis { trade, settlement }

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
    this.dateBasis = ReportDateBasis.trade,
    this.sourceMovement = '',
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
  final ReportDateBasis dateBasis;
  final String sourceMovement;

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
    dateBasis: dateBasis,
    sourceMovement: sourceMovement,
  );
}

class ReportImportException implements Exception {
  const ReportImportException(this.message);
  final String message;
  @override
  String toString() => message;
}
