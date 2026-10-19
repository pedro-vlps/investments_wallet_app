import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:investments_wallet/dividends/data/sqlite_dividend_repository.dart';
import 'package:investments_wallet/dividends/domain/dividend_period.dart';
import 'package:investments_wallet/dividends/domain/dividend_report.dart';
import 'package:investments_wallet/portfolio/data/sqlite_portfolio_repository.dart';

void main() {
  late Directory directory;
  late String demo;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('wallet_dividends_');
    demo = await File('assets/demo_portfolio.json').readAsString();
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'new schema persists all event details and matches portfolio received balances',
    () async {
      final path = '${directory.path}/portfolio.sqlite3';
      final portfolio = SqlitePortfolioRepository(path);
      await portfolio.initialize(demo);
      await portfolio.initialize(demo);
      final dividends = await SqliteDividendRepository(path).loadData();
      expect(dividends.payments.length, 26);
      expect(dividends.payments.where((p) => p.received).length, 22);
      expect(dividends.valuations.length, 58);
      final original = dividends.payments.singleWhere(
        (p) => p.id == 'demo-petr4-20261001',
      );
      expect(original.perShareMicros, 3200000);
      expect(original.eligibleQuantity, 100);
      expect(original.cumDate, isNotNull);
      expect(original.exDate!.isAfter(original.cumDate!), true);
      final totals = DividendReport(
        dividends,
        DateTime(2026, 10, 18),
      ).receivedBySymbol(DividendPeriod.inception);
      for (final position in await portfolio.loadPositions()) {
        expect(position.dividendsReceivedCents, totals[position.symbol]);
      }
    },
  );

  test(
    'v2 migration preserves unknown payments without fabricated entitlement dates',
    () async {
      final path = '${directory.path}/legacy.sqlite3';
      final database = sqlite3.open(path);
      database.execute(
        'CREATE TABLE positions (symbol TEXT PRIMARY KEY, company TEXT, quantity INTEGER, average_cost_cents INTEGER)',
      );
      database.execute(
        'CREATE TABLE quotes (symbol TEXT PRIMARY KEY, price_cents INTEGER, quoted_at TEXT, source TEXT)',
      );
      database.execute(
        'CREATE TABLE dividends (id TEXT PRIMARY KEY, symbol TEXT, amount_cents INTEGER, paid_at TEXT)',
      );
      database.execute(
        "INSERT INTO positions VALUES ('PETR4', 'Custom', 777, 999)",
      );
      database.execute(
        "INSERT INTO dividends VALUES ('custom', 'PETR4', 123, '2026-10-01')",
      );
      database.execute('PRAGMA user_version = 2');
      database.close();
      final portfolio = SqlitePortfolioRepository(path);
      await portfolio.initialize(demo);
      await portfolio.initialize(demo);
      final data = await SqliteDividendRepository(path).loadData();
      final payment = data.payments.single;
      expect(payment.amountCents, 123);
      expect(payment.received, true);
      expect(payment.cumDate, isNull);
      expect(payment.exDate, isNull);
      expect(payment.perShareMicros, isNull);
      expect(data.valuations, isEmpty);
    },
  );
}
