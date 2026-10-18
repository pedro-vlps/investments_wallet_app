import 'market_quote.dart';

abstract interface class QuoteProvider {
  Future<List<MarketQuote>> fetchQuotes(List<String> symbols);
}

class QuoteException implements Exception {
  const QuoteException(this.message);
  final String message;
}
