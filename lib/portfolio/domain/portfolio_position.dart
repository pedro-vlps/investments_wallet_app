import '../../quotes/domain/market_quote.dart';

class PortfolioPosition {
  PortfolioPosition({
    required this.symbol,
    required this.company,
    required this.quantity,
    required this.averageCostCents,
    required this.quote,
  }) {
    if (quantity <= 0 ||
        averageCostCents <= 0 ||
        symbol != quote.symbol ||
        company.isEmpty) {
      throw ArgumentError('Invalid portfolio position');
    }
  }

  final String symbol;
  final String company;
  final int quantity;
  final int averageCostCents;
  final MarketQuote quote;

  int get investedCents => quantity * averageCostCents;
  int get marketValueCents => quantity * quote.priceCents;
  int get unrealizedGainCents => marketValueCents - investedCents;
  double get unrealizedGainPercent => unrealizedGainCents / investedCents * 100;
}
