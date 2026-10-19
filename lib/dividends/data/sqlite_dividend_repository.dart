import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import '../domain/dividend_payment.dart';
import '../domain/dividend_repository.dart';

class SqliteDividendRepository implements DividendRepository {
  const SqliteDividendRepository(this.databasePath);
  final String databasePath;

  /// Public infrastructure contract used by portfolio valuation reads.
  static Map<String, int> receivedTotals(Database database, DateTime asOf) => {
    for (final row in database.select(
      '''SELECT symbol, SUM(amount_cents) AS total
      FROM dividends WHERE is_received = 1 AND paid_at <= ? GROUP BY symbol''',
      [asOf.toIso8601String().substring(0, 10)],
    ))
      row['symbol'] as String: row['total'] as int,
  };

  @override
  Future<DividendData> loadData() => Isolate.run(() {
    final database = sqlite3.open(databasePath);
    try {
      final payments = database
          .select('SELECT * FROM dividends ORDER BY paid_at DESC, id')
          .map(
            (r) => DividendPayment(
              id: r['id'] as String,
              symbol: r['symbol'] as String,
              amountCents: r['amount_cents'] as int,
              paymentDate: DateTime.parse(r['paid_at'] as String),
              received: r['is_received'] == 1,
              kind: r['kind'] == 'JCP'
                  ? DividendKind.interestOnEquity
                  : DividendKind.dividend,
              perShareMicros: r['per_share_micros'] as int?,
              eligibleQuantity: r['eligible_quantity'] as int?,
              cumDate: r['cum_date'] == null
                  ? null
                  : DateTime.parse(r['cum_date'] as String),
              exDate: r['ex_date'] == null
                  ? null
                  : DateTime.parse(r['ex_date'] as String),
            ),
          )
          .toList();
      final valuations = database
          .select('SELECT * FROM portfolio_valuations ORDER BY valued_at')
          .map(
            (r) => PortfolioValuation(
              date: DateTime.parse(r['valued_at'] as String),
              investedCents: r['invested_cents'] as int,
              marketValueCents: r['market_value_cents'] as int,
            ),
          )
          .toList();
      return DividendData(payments: payments, valuations: valuations);
    } finally {
      database.close();
    }
  });
}
