import 'package:flutter_test/flutter_test.dart';
import 'package:investments_wallet/dividends/domain/dividend_payment.dart';
import 'package:investments_wallet/dividends/domain/dividend_period.dart';
import 'package:investments_wallet/dividends/domain/dividend_report.dart';
import 'package:investments_wallet/dividends/domain/dividend_repository.dart';

DividendPayment payment(
  String id,
  String symbol,
  int cents,
  DateTime date, {
  bool received = true,
}) => DividendPayment(
  id: id,
  symbol: symbol,
  amountCents: cents,
  paymentDate: date,
  received: received,
  kind: DividendKind.dividend,
);

void main() {
  final now = DateTime(2026, 10, 18);
  final data = DividendData(
    payments: [
      payment('old', 'PETR4', 1000, DateTime(2022, 1, 5)),
      payment('before', 'PETR4', 20000, DateTime(2026, 9, 17)),
      payment('boundary', 'PETR4', 10000, DateTime(2026, 9, 18)),
      payment('today', 'ITUB4', 3000, now),
      payment(
        'overdue',
        'ITUB4',
        5000,
        DateTime(2026, 10, 10),
        received: false,
      ),
      payment('future', 'PETR4', 40000, DateTime(2026, 11, 2), received: false),
    ],
    valuations: [
      PortfolioValuation(
        date: DateTime(2026, 9, 30),
        investedCents: 100000,
        marketValueCents: 105000,
      ),
      PortfolioValuation(
        date: now,
        investedCents: 100000,
        marketValueCents: 102000,
      ),
    ],
  );
  final report = DividendReport(data, now);

  test('rolling periods clamp month ends and include exact boundaries', () {
    expect(
      DividendPeriod.month.start(DateTime(2026, 3, 31)),
      DateTime(2026, 2, 28),
    );
    expect(
      DividendPeriod.month.start(DateTime(2024, 3, 31)),
      DateTime(2024, 2, 29),
    );
    expect(DividendPeriod.year.start(now), DateTime(2025, 10, 18));
    expect(DividendPeriod.sixMonths.start(now), DateTime(2026, 4, 18));
    expect(DividendPeriod.threeMonths.start(now), DateTime(2026, 7, 18));
    expect(DividendPeriod.twoYears.start(now), DateTime(2024, 10, 18));
    expect(DividendPeriod.fiveYears.start(now), DateTime(2021, 10, 18));
    expect(report.receivedBySymbol(DividendPeriod.month), {
      'PETR4': 10000,
      'ITUB4': 3000,
    });
  });

  test('provisions are separate and never appear as received cash', () {
    expect(report.receivedTotal(DividendPeriod.inception), 34000);
    expect(report.provisionedTotal(DividendPeriod.inception), 45000);
    expect(report.receivedTotal(DividendPeriod.month), 13000);
    expect(report.provisionedTotal(DividendPeriod.month), 5000);
    expect(
      report.payments(DividendPeriod.month).any((p) => p.id == 'future'),
      false,
    );
    expect(report.payments(DividendPeriod.inception).first.id, 'future');
  });

  test('monthly bars sum filtered payments and exclude future provisions', () {
    final months = report.monthly(DividendPeriod.month);
    expect(months.map((m) => m.month), [DateTime(2026, 9), DateTime(2026, 10)]);
    expect(months.map((m) => m.receivedCents), [10000, 3000]);
  });

  test(
    'return lines use inception cash, not just the selected cash window',
    () {
      final months = report.monthly(DividendPeriod.month, withReturns: true);
      expect(months.first.priceReturnPercent, 5);
      expect(months.first.totalReturnPercent, 36);
      expect(months.last.priceReturnPercent, 2);
      expect(months.last.totalReturnPercent, 36);
    },
  );

  test(
    'empty months are filled and missing valuations do not invent returns',
    () {
      final months = report.monthly(
        DividendPeriod.threeMonths,
        withReturns: true,
      );
      expect(months.first.month, DateTime(2026, 7));
      expect(months.first.receivedCents, 0);
      expect(months.first.totalReturnPercent, isNull);
      expect(months[1].totalReturnPercent, isNull);
      final empty = DividendReport(
        const DividendData(payments: [], valuations: []),
        now,
      );
      expect(empty.monthly(DividendPeriod.inception).single.receivedCents, 0);
      expect(empty.receivedBySymbol(DividendPeriod.inception), isEmpty);
    },
  );

  test('pagination retains all events with at most ten rows', () {
    final many = DividendReport(
      DividendData(
        payments: [
          for (var i = 0; i < 23; i++)
            payment(
              'event-$i',
              'PETR4',
              100,
              DateTime(2026, 10, i + 1),
              received: false,
            ),
        ],
        valuations: [],
      ),
      now,
    );
    expect(many.page(DividendPeriod.inception, 0).length, 10);
    expect(many.page(DividendPeriod.inception, 1).length, 10);
    expect(many.page(DividendPeriod.inception, 2).length, 3);
    final ids = [
      for (var page = 0; page < 3; page++)
        ...many.page(DividendPeriod.inception, page).map((p) => p.id),
    ];
    expect(ids.toSet().length, 23);
  });
}
