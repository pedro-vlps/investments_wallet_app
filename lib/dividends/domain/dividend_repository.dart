import 'dividend_payment.dart';
import 'dividend_market_data.dart';

class PortfolioValuation {
  PortfolioValuation({
    required this.date,
    required this.investedCents,
    required this.marketValueCents,
    this.priceReturnPercent,
    this.totalReturnPercent,
  }) {
    if (investedCents <= 0 || marketValueCents < 0) {
      throw ArgumentError('Invalid portfolio valuation');
    }
  }
  final DateTime date;
  final int investedCents;
  final int marketValueCents;
  final double? priceReturnPercent;
  final double? totalReturnPercent;
}

class DividendData {
  const DividendData({
    required this.payments,
    required this.valuations,
    this.demo = true,
    this.warnings = const [],
    this.checkedAt,
    this.announcements = const [],
  });
  final bool demo;
  final List<DividendPayment> payments;
  final List<PortfolioValuation> valuations;
  final List<String> warnings;
  final DateTime? checkedAt;
  final List<DividendAnnouncement> announcements;
}

abstract interface class DividendRepository {
  Future<DividendData> loadData();
}
