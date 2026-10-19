import '../../quotes/domain/market_quote.dart';

class PortfolioPosition {
  PortfolioPosition({
    required this.symbol,
    required this.company,
    required this.quantity,
    required this.averageCostCents,
    required this.quote,
    this.dividendsReceivedCents = 0,
  }) {
    if (quantity <= 0 ||
        averageCostCents <= 0 ||
        symbol != quote.symbol ||
        company.isEmpty ||
        dividendsReceivedCents < 0) {
      throw ArgumentError('Invalid portfolio position');
    }
  }

  final String symbol;
  final String company;
  final int quantity;
  final int averageCostCents;
  final MarketQuote quote;
  final int dividendsReceivedCents;

  int get investedCents => quantity * averageCostCents;
  int get marketValueCents => quantity * quote.priceCents;
  int get unrealizedGainCents => marketValueCents - investedCents;
  double get unrealizedGainPercent => unrealizedGainCents / investedCents * 100;
  int get totalGainCents => unrealizedGainCents + dividendsReceivedCents;
  double get totalGainPercent => totalGainCents / investedCents * 100;
  double allocationPercent(int portfolioMarketValueCents) =>
      portfolioMarketValueCents <= 0
      ? 0
      : marketValueCents / portfolioMarketValueCents * 100;
}
