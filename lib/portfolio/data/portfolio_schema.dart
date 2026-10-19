import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

void initializePortfolioSchema(Database database, String demoJson) {
  database.execute('PRAGMA foreign_keys = ON');
  database.execute('BEGIN IMMEDIATE');
  try {
    final version =
        database.select('PRAGMA user_version').single['user_version'] as int;
    if (version > 2) throw StateError('Unsupported database schema');
    if (version == 2) {
      database.execute('COMMIT');
      return;
    }
    final demo = jsonDecode(demoJson) as Map<String, dynamic>;
    if (version == 0) {
      database.execute('''
        CREATE TABLE positions (
          symbol TEXT PRIMARY KEY, company TEXT NOT NULL,
          quantity INTEGER NOT NULL CHECK (quantity > 0),
          average_cost_cents INTEGER NOT NULL CHECK (average_cost_cents > 0)
        )
      ''');
      database.execute('''
        CREATE TABLE quotes (
          symbol TEXT PRIMARY KEY REFERENCES positions(symbol),
          price_cents INTEGER NOT NULL CHECK (price_cents > 0),
          quoted_at TEXT NOT NULL, source TEXT NOT NULL
        )
      ''');
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
          DateTime.parse(row['quotedAt'] as String).toUtc().toIso8601String(),
          row['source'],
        ]);
      }
    }
    if (version < 2) {
      database.execute('''
      CREATE TABLE dividends (
        id TEXT PRIMARY KEY, symbol TEXT NOT NULL REFERENCES positions(symbol),
        amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
        paid_at TEXT NOT NULL
      )
    ''');
      database.execute('CREATE INDEX dividends_symbol ON dividends(symbol)');
      // v1 only exposed demo holdings. Seed demo payments for exact matching
      // holdings, preserving quotes and avoiding invented payments for other data.
      final holdings = (demo['positions'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final item in demo['dividends'] as List<dynamic>? ?? const []) {
        final payment = item as Map<String, dynamic>;
        final matches = holdings.where((p) => p['symbol'] == payment['symbol']);
        if (matches.isEmpty) continue;
        final holding = matches.single;
        database.execute(
          '''
        INSERT INTO dividends (id, symbol, amount_cents, paid_at)
        SELECT ?, symbol, ?, ? FROM positions
        WHERE symbol = ? AND company = ? AND quantity = ? AND average_cost_cents = ?
      ''',
          [
            payment['id'],
            payment['amountCents'],
            payment['paidAt'],
            holding['symbol'],
            holding['company'],
            holding['quantity'],
            holding['averageCostCents'],
          ],
        );
      }
    }
    database.execute('PRAGMA user_version = 2');
    database.execute('COMMIT');
  } catch (_) {
    database.execute('ROLLBACK');
    rethrow;
  }
}
