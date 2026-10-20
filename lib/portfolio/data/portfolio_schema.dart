import 'package:sqlite3/sqlite3.dart';
import '../../dividends/data/dividend_schema.dart';
import '../../reports/data/report_schema.dart';

void initializePortfolioSchema(Database database) {
  database.execute('PRAGMA foreign_keys = ON');
  database.execute('BEGIN IMMEDIATE');
  try {
    final version =
        database.select('PRAGMA user_version').single['user_version'] as int;
    if (version > 5) throw StateError('Unsupported database schema');
    if (version == 5) {
      database.execute('COMMIT');
      return;
    }
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
    }
    if (version < 3) migrateDividendSchema(database);
    initializeReportSchema(database);
    database.execute('PRAGMA user_version = 5');
    database.execute('COMMIT');
  } catch (_) {
    database.execute('ROLLBACK');
    rethrow;
  }
}
