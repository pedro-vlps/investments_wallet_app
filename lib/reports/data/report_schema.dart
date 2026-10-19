import 'package:sqlite3/sqlite3.dart';

void initializeReportSchema(Database database) {
  database.execute('''CREATE TABLE IF NOT EXISTS imported_reports (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, imported_at TEXT NOT NULL,
    relative_path TEXT NOT NULL, duplicate_trades INTEGER NOT NULL,
    issues_json TEXT NOT NULL)''');
  database.execute(
    '''CREATE TABLE IF NOT EXISTS report_trades (
    id TEXT PRIMARY KEY, symbol TEXT NOT NULL, name TEXT NOT NULL,
    broker TEXT NOT NULL, traded_at TEXT NOT NULL, side TEXT NOT NULL,
    quantity_micros INTEGER NOT NULL CHECK(quantity_micros > 0),
    price_micros INTEGER NOT NULL CHECK(price_micros > 0),
    total_cents INTEGER NOT NULL CHECK(total_cents > 0), category TEXT NOT NULL)''',
  );
  database.execute('''CREATE TABLE IF NOT EXISTS report_lines (
    report_id TEXT NOT NULL REFERENCES imported_reports(id),
    trade_id TEXT NOT NULL REFERENCES report_trades(id), is_new INTEGER NOT NULL,
    PRIMARY KEY(report_id, trade_id))''');
  database.execute('''CREATE TABLE IF NOT EXISTS imported_quotes (
    symbol TEXT PRIMARY KEY, price_cents INTEGER NOT NULL CHECK(price_cents > 0),
    quoted_at TEXT NOT NULL, source TEXT NOT NULL)''');
}
