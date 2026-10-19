import 'package:sqlite3/sqlite3.dart';

void migrateDividendSchema(Database database) {
  database.execute('ALTER TABLE dividends ADD COLUMN per_share_micros INTEGER');
  database.execute(
    'ALTER TABLE dividends ADD COLUMN eligible_quantity INTEGER',
  );
  database.execute('ALTER TABLE dividends ADD COLUMN cum_date TEXT');
  database.execute('ALTER TABLE dividends ADD COLUMN ex_date TEXT');
  database.execute(
    "ALTER TABLE dividends ADD COLUMN kind TEXT NOT NULL DEFAULT 'DIVIDEND' CHECK (kind IN ('DIVIDEND', 'JCP'))",
  );
  database.execute(
    'ALTER TABLE dividends ADD COLUMN is_received INTEGER NOT NULL DEFAULT 1 CHECK (is_received IN (0, 1))',
  );
  database.execute('''CREATE TABLE portfolio_valuations (
    valued_at TEXT PRIMARY KEY,
    invested_cents INTEGER NOT NULL CHECK (invested_cents > 0),
    market_value_cents INTEGER NOT NULL CHECK (market_value_cents >= 0)
  )''');
}
