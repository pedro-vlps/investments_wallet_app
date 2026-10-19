import '../../quotes/domain/market_quote.dart';
import 'asset_category.dart';

class PortfolioPosition {
  PortfolioPosition({
    required this.symbol,
    required this.company,
    required this.quantity,
    required this.averageCostCents,
    required this.quote,
    this.dividendsReceivedCents = 0,
    this.category = AssetCategory.stock,
    this.imported = false,
    this.costBasisCents,
  }) {
    if (quantity <= 0 ||
        !quantity.isFinite ||
        averageCostCents < 0 ||
        (costBasisCents == null && averageCostCents == 0) ||
        symbol != quote.symbol ||
        company.isEmpty ||
        dividendsReceivedCents < 0 ||
        (costBasisCents != null && costBasisCents! < 0)) {
      throw ArgumentError('Invalid portfolio position');
    }
  }

  final String symbol;
  final String company;
  final num quantity;
  final int averageCostCents;
  final MarketQuote quote;
  final int dividendsReceivedCents;
  final AssetCategory category;
  final bool imported;
  final int? costBasisCents;

  int get investedCents =>
      costBasisCents ?? (quantity * averageCostCents).round();
  int get marketValueCents => (quantity * quote.priceCents).round();
  int get unrealizedGainCents => marketValueCents - investedCents;
  double get unrealizedGainPercent =>
      investedCents == 0 ? 0 : unrealizedGainCents / investedCents * 100;
  int get totalGainCents => unrealizedGainCents + dividendsReceivedCents;
  double get totalGainPercent =>
      investedCents == 0 ? 0 : totalGainCents / investedCents * 100;
  double allocationPercent(int portfolioMarketValueCents) =>
      portfolioMarketValueCents <= 0
      ? 0
      : marketValueCents / portfolioMarketValueCents * 100;
}
