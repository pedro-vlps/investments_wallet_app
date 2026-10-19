import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';
import '../../dividends/data/sqlite_dividend_repository.dart';
import '../../reports/data/sqlite_report_repository.dart';

import '../../quotes/domain/market_quote.dart';
import '../domain/portfolio_position.dart';
import '../domain/portfolio_repository.dart';
import 'portfolio_schema.dart';
import 'imported_portfolio_positions.dart';

class SqlitePortfolioRepository implements PortfolioRepository {
  SqlitePortfolioRepository(this.databasePath);
  final String databasePath;

  // Each operation opens its own connection in a worker isolate. SQLite work
  // never blocks animation, and no native connection crosses isolate boundaries.
  Future<void> initialize() => Isolate.run(() {
    final database = sqlite3.open(databasePath);
    try {
      initializePortfolioSchema(database);
    } finally {
      database.close();
    }
  });

  @override
  Future<List<PortfolioPosition>> loadPositions() => Isolate.run(() {
    final database = sqlite3.open(databasePath);
    try {
      if (SqliteReportRepository.hasReports(database)) {
        return loadImportedPortfolioPositions(database);
      }
      final dividends = SqliteDividendRepository.receivedTotals(
        database,
        DateTime.now(),
      );
      return database
          .select('''
        SELECT p.*, q.price_cents, q.quoted_at, q.source
        FROM positions p JOIN quotes q ON q.symbol = p.symbol
        ORDER BY p.symbol
      ''')
          .map(
            (row) => PortfolioPosition(
              symbol: row['symbol'] as String,
              company: row['company'] as String,
              quantity: row['quantity'] as int,
              dividendsReceivedCents: dividends[row['symbol']] ?? 0,
              averageCostCents: row['average_cost_cents'] as int,
              quote: MarketQuote(
                symbol: row['symbol'] as String,
                priceCents: row['price_cents'] as int,
                quotedAt: DateTime.parse(row['quoted_at'] as String),
                source: row['source'] as String,
              ),
            ),
          )
          .toList();
    } finally {
      database.close();
    }
  });

  @override
  Future<void> saveQuotes(List<MarketQuote> quotes) => Isolate.run(() {
    final database = sqlite3.open(databasePath);
    try {
      database.execute('PRAGMA foreign_keys = ON');
      database.execute('BEGIN IMMEDIATE');
      try {
        final table = SqliteReportRepository.hasReports(database)
            ? 'imported_quotes'
            : 'quotes';
        for (final quote in quotes) {
          database.execute(
            '''
            INSERT INTO $table VALUES (?, ?, ?, ?)
            ON CONFLICT(symbol) DO UPDATE SET price_cents = excluded.price_cents,
              quoted_at = excluded.quoted_at, source = excluded.source
            WHERE excluded.quoted_at >= $table.quoted_at
          ''',
            [
              quote.symbol,
              quote.priceCents,
              quote.quotedAt.toUtc().toIso8601String(),
              quote.source,
            ],
          );
        }
        database.execute('COMMIT');
      } catch (_) {
        database.execute('ROLLBACK');
        rethrow;
      }
    } finally {
      database.close();
    }
  });

  @override
  Future<void> close() async {
    // Connections are scoped to individual operations.
  }
}
