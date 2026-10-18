class MarketQuote {
  MarketQuote({
    required this.symbol,
    required this.priceCents,
    required this.quotedAt,
    required this.source,
  }) {
    if (!RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(symbol) ||
        priceCents <= 0 ||
        source.isEmpty) {
      throw ArgumentError('Invalid market quote');
    }
  }

  final String symbol;
  final int priceCents;
  final DateTime quotedAt;
  final String source;
}
