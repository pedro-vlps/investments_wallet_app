import 'package:sqlite3/sqlite3.dart';

void migrateDividendSchema(Database database, Map<String, dynamic> demo) {
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
  final holdings = (demo['positions'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  for (final item in demo['dividendEvents'] as List<dynamic>? ?? const []) {
    final event = item as Map<String, dynamic>;
    final matches = holdings.where((p) => p['symbol'] == event['symbol']);
    if (matches.isEmpty) continue;
    final holding = matches.single;
    final isOriginal = database
        .select(
          '''SELECT symbol FROM positions
      WHERE symbol = ? AND company = ? AND quantity = ? AND average_cost_cents = ?''',
          [
            holding['symbol'],
            holding['company'],
            holding['quantity'],
            holding['averageCostCents'],
          ],
        )
        .isNotEmpty;
    if (!isOriginal) continue;
    database.execute(
      '''INSERT INTO dividends
      (id, symbol, amount_cents, paid_at, per_share_micros, eligible_quantity, cum_date, ex_date, kind, is_received)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET per_share_micros = excluded.per_share_micros,
        eligible_quantity = excluded.eligible_quantity, cum_date = excluded.cum_date,
        ex_date = excluded.ex_date, kind = excluded.kind
      WHERE dividends.symbol = excluded.symbol AND dividends.amount_cents = excluded.amount_cents
        AND dividends.paid_at = excluded.paid_at
    ''',
      [
        event['id'],
        event['symbol'],
        event['amountCents'],
        event['paidAt'],
        event['perShareMicros'],
        event['quantity'],
        event['cumDate'],
        event['exDate'],
        event['kind'],
        event['received'] == true ? 1 : 0,
      ],
    );
  }
  // A demo valuation is meaningful only when the whole portfolio still matches
  // the demo. Never attach fabricated history to a different user portfolio.
  final rows = database.select('SELECT * FROM positions');
  final isDemo =
      rows.length == holdings.length &&
      holdings.every(
        (h) => rows.any(
          (r) =>
              r['symbol'] == h['symbol'] &&
              r['company'] == h['company'] &&
              r['quantity'] == h['quantity'] &&
              r['average_cost_cents'] == h['averageCostCents'],
        ),
      );
  if (isDemo) {
    for (final item in demo['valuations'] as List<dynamic>? ?? const []) {
      final value = item as Map<String, dynamic>;
      database.execute('INSERT INTO portfolio_valuations VALUES (?, ?, ?)', [
        value['date'],
        value['investedCents'],
        value['marketValueCents'],
      ]);
    }
  }
}
