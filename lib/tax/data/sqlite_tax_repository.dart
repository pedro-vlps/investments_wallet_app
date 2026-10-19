import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import '../domain/tax_month.dart';
import '../domain/tax_repository.dart';
import 'tax_schema.dart';

class SqliteTaxRepository implements TaxRepository {
  const SqliteTaxRepository(this.databasePath);
  final String databasePath;

  Future<T> _withDatabase<T>(T Function(Database) action) => Isolate.run(() {
    final database = sqlite3.open(databasePath);
    try {
      database.execute('PRAGMA busy_timeout = 5000');
      initializeTaxSchema(database);
      return action(database);
    } finally {
      database.close();
    }
  });

  @override
  Future<TaxYearData> loadYear(int year) => _withDatabase((db) {
    final opening = db.select('SELECT * FROM tax_openings WHERE year = ?', [
      year,
    ]);
    final months = db.select(
      'SELECT * FROM tax_months WHERE year = ? ORDER BY month',
      [year],
    );
    return TaxYearData(
      opening.isEmpty
          ? null
          : TaxOpening(
              year: year,
              commonLoss: opening.single['common_loss'] as int,
              dayTradeLoss: opening.single['day_trade_loss'] as int,
              fundLoss: opening.single['fund_loss'] as int,
              smallDarf: opening.single['small_darf'] as int,
            ),
      months
          .map(
            (r) => TaxMonth(
              year: year,
              month: r['month'] as int,
              stockSales: r['stock_sales'] as int,
              stockResult: r['stock_result'] as int,
              otherCommonResult: r['other_common_result'] as int,
              dayTradeResult: r['day_trade_result'] as int,
              fundResult: r['fund_result'] as int,
              commonWithheld: r['common_withheld'] as int,
              dayTradeWithheld: r['day_trade_withheld'] as int,
              fundWithheld: r['fund_withheld'] as int,
              paid: r['paid'] as int,
              notes: r['notes'] as String,
            ),
          )
          .toList(),
    );
  });

  @override
  Future<void> saveMonth(TaxMonth month) async {
    month.validate();
    await _withDatabase(
      (db) => db.execute(
        'INSERT OR REPLACE INTO tax_months VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [month.year, month.month, ...month.values, month.notes],
      ),
    );
  }

  @override
  Future<void> deleteMonth(int year, int month) => _withDatabase(
    (db) => db.execute('DELETE FROM tax_months WHERE year = ? AND month = ?', [
      year,
      month,
    ]),
  );

  @override
  Future<void> saveOpening(TaxOpening opening) async {
    opening.validate();
    await _withDatabase(
      (db) => db.execute(
        'INSERT OR REPLACE INTO tax_openings VALUES (?, ?, ?, ?, ?)',
        [
          opening.year,
          opening.commonLoss,
          opening.dayTradeLoss,
          opening.fundLoss,
          opening.smallDarf,
        ],
      ),
    );
  }

  @override
  Future<String?> loadCheckState() => _withDatabase((db) {
    final rows = db.select('SELECT state FROM tax_rule_checks WHERE id = 1');
    return rows.isEmpty ? null : rows.single['state'] as String;
  });

  @override
  Future<void> saveCheckState(String state) => _withDatabase(
    (db) => db.execute('INSERT OR REPLACE INTO tax_rule_checks VALUES (1, ?)', [
      state,
    ]),
  );
}
