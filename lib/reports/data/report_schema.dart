import 'package:sqlite3/sqlite3.dart';
import '../../dividends/data/reported_dividend_store.dart';

void initializeReportSchema(Database database) {
  database.execute('''CREATE TABLE IF NOT EXISTS imported_reports (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, imported_at TEXT NOT NULL,
    relative_path TEXT NOT NULL, duplicate_trades INTEGER NOT NULL,
    issues_json TEXT NOT NULL)''');
  database.execute(
    '''CREATE TABLE IF NOT EXISTS report_trades (
    id TEXT PRIMARY KEY, symbol TEXT NOT NULL, name TEXT NOT NULL,
    broker TEXT NOT NULL, occurred_at TEXT NOT NULL, side TEXT NOT NULL,
    quantity_micros INTEGER NOT NULL CHECK(quantity_micros > 0),
    price_micros INTEGER NOT NULL CHECK(price_micros > 0),
    total_cents INTEGER NOT NULL CHECK(total_cents > 0), category TEXT NOT NULL)''',
  );
  final columns = database
      .select('PRAGMA table_info(report_trades)')
      .map((row) => row['name'])
      .toSet();
  if (columns.contains('traded_at') && !columns.contains('occurred_at')) {
    database.execute(
      'ALTER TABLE report_trades RENAME COLUMN traded_at TO occurred_at',
    );
  }
  if (!columns.contains('date_basis')) {
    database.execute(
      "ALTER TABLE report_trades ADD COLUMN date_basis TEXT NOT NULL DEFAULT 'trade' CHECK(date_basis IN ('trade', 'settlement'))",
    );
  }
  if (!columns.contains('source_movement')) {
    database.execute(
      "ALTER TABLE report_trades ADD COLUMN source_movement TEXT NOT NULL DEFAULT ''",
    );
  }
  database.execute('''CREATE TABLE IF NOT EXISTS report_lines (
    report_id TEXT NOT NULL REFERENCES imported_reports(id),
    trade_id TEXT NOT NULL REFERENCES report_trades(id), is_new INTEGER NOT NULL,
    PRIMARY KEY(report_id, trade_id))''');
  database.execute('''CREATE TABLE IF NOT EXISTS imported_quotes (
    symbol TEXT PRIMARY KEY, price_cents INTEGER NOT NULL CHECK(price_cents > 0),
    quoted_at TEXT NOT NULL, source TEXT NOT NULL)''');
  ReportedDividendStore.initialize(database);
}
