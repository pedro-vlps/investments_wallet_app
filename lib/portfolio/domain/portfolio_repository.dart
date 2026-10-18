import '../../quotes/domain/market_quote.dart';
import 'portfolio_position.dart';

abstract interface class PortfolioRepository {
  Future<List<PortfolioPosition>> loadPositions();
  Future<void> saveQuotes(List<MarketQuote> quotes);
  Future<void> close();
}
