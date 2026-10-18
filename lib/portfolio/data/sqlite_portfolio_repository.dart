import 'dart:convert';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import '../../quotes/domain/market_quote.dart';
import '../domain/portfolio_position.dart';
import '../domain/portfolio_repository.dart';

class SqlitePortfolioRepository implements PortfolioRepository {
  SqlitePortfolioRepository(this.databasePath);
  final String databasePath;

  // Each operation opens its own connection in a worker isolate. SQLite work
  // never blocks animation, and no native connection crosses isolate boundaries.
  Future<void> initialize(String demoJson) => Isolate.run(() {
    final database = sqlite3.open(databasePath);
    try {
      database.execute('PRAGMA foreign_keys = ON');
      final version =
          database.select('PRAGMA user_version').single['user_version'] as int;
      if (version > 1) throw StateError('Unsupported database schema');
      database.execute('BEGIN IMMEDIATE');
      try {
        database.execute('''
          CREATE TABLE IF NOT EXISTS positions (
            symbol TEXT PRIMARY KEY, company TEXT NOT NULL,
            quantity INTEGER NOT NULL CHECK (quantity > 0),
            average_cost_cents INTEGER NOT NULL CHECK (average_cost_cents > 0)
          )
        ''');
        database.execute('''
          CREATE TABLE IF NOT EXISTS quotes (
            symbol TEXT PRIMARY KEY REFERENCES positions(symbol),
            price_cents INTEGER NOT NULL CHECK (price_cents > 0),
            quoted_at TEXT NOT NULL, source TEXT NOT NULL
          )
        ''');
        if (version == 0) {
          final demo = jsonDecode(demoJson) as Map<String, dynamic>;
          for (final item in demo['positions'] as List<dynamic>) {
            final row = item as Map<String, dynamic>;
            database.execute('INSERT INTO positions VALUES (?, ?, ?, ?)', [
              row['symbol'],
              row['company'],
              row['quantity'],
              row['averageCostCents'],
            ]);
          }
          for (final item in demo['quotes'] as List<dynamic>) {
            final row = item as Map<String, dynamic>;
            database.execute('INSERT INTO quotes VALUES (?, ?, ?, ?)', [
              row['symbol'],
              row['priceCents'],
              DateTime.parse(
                row['quotedAt'] as String,
              ).toUtc().toIso8601String(),
              row['source'],
            ]);
          }
          database.execute('PRAGMA user_version = 1');
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
  Future<List<PortfolioPosition>> loadPositions() => Isolate.run(() {
    final database = sqlite3.open(databasePath);
    try {
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
        for (final quote in quotes) {
          database.execute(
            '''
            INSERT INTO quotes VALUES (?, ?, ?, ?)
            ON CONFLICT(symbol) DO UPDATE SET price_cents = excluded.price_cents,
              quoted_at = excluded.quoted_at, source = excluded.source
            WHERE excluded.quoted_at >= quotes.quoted_at
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
