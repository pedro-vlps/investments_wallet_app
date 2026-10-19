import 'dividend_payment.dart';

class PortfolioValuation {
  PortfolioValuation({
    required this.date,
    required this.investedCents,
    required this.marketValueCents,
  }) {
    if (investedCents <= 0 || marketValueCents < 0) {
      throw ArgumentError('Invalid portfolio valuation');
    }
  }
  final DateTime date;
  final int investedCents;
  final int marketValueCents;
}

class DividendData {
  const DividendData({
    required this.payments,
    required this.valuations,
    this.demo = true,
  });
  final bool demo;
  final List<DividendPayment> payments;
  final List<PortfolioValuation> valuations;
}

abstract interface class DividendRepository {
  Future<DividendData> loadData();
}
