import 'package:sqlite3/sqlite3.dart';

import '../../quotes/domain/market_quote.dart';
import '../../reports/data/sqlite_report_repository.dart';
import '../../reports/domain/imported_holding.dart';
import '../domain/portfolio_position.dart';

List<PortfolioPosition> loadImportedPortfolioPositions(Database database) {
  final grouped = <String, List<ImportedHolding>>{};
  for (final holding in SqliteReportRepository.holdings(database)) {
    grouped.putIfAbsent(holding.symbol, () => []).add(holding);
  }
  return (grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map(
    (entry) {
      final holdings = entry.value;
      final quantityMicros = holdings.fold<int>(
        0,
        (sum, h) => sum + h.quantityMicros,
      );
      final cost = holdings.fold<int>(0, (sum, h) => sum + h.costCents);
      final latest =
          (holdings.toList()..sort((a, b) => b.date.compareTo(a.date))).first;
      final savedQuotes = database.select(
        'SELECT * FROM imported_quotes WHERE symbol = ?',
        [entry.key],
      );
      final saved = savedQuotes.isEmpty ? null : savedQuotes.single;
      final useSaved =
          saved != null &&
          !DateTime.parse(saved['quoted_at'] as String).isBefore(latest.date);
      return PortfolioPosition(
        symbol: entry.key,
        company: latest.name,
        quantity: quantityMicros / 1000000,
        averageCostCents: (cost * 1000000 / quantityMicros).round(),
        costBasisCents: cost,
        category: latest.category,
        imported: true,
        quote: MarketQuote(
          symbol: entry.key,
          priceCents: useSaved
              ? saved['price_cents'] as int
              : (latest.lastPriceMicros / 10000).round().clamp(
                  1,
                  1000000000000,
                ),
          quotedAt: useSaved
              ? DateTime.parse(saved['quoted_at'] as String)
              : latest.date,
          source: useSaved
              ? saved['source'] as String
              : 'Preço da última operação · sem cotação atual',
        ),
      );
    },
  ).toList();
}
