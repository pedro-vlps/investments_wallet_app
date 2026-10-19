import 'dividend_payment.dart';
import 'dividend_period.dart';
import 'dividend_repository.dart';

class DividendMonth {
  const DividendMonth({
    required this.month,
    required this.receivedCents,
    this.priceReturnPercent,
    this.totalReturnPercent,
  });
  final DateTime month;
  final int receivedCents;
  final double? priceReturnPercent;
  final double? totalReturnPercent;
}

class DividendReport {
  DividendReport(this.data, this.asOf);
  final DividendData data;
  final DateTime asOf;
  static const pageSize = 10;

  List<DividendPayment> payments(DividendPeriod period) =>
      data.payments
          .where(
            (p) => period.contains(p.paymentDate, asOf, includeFuture: true),
          )
          .toList()
        ..sort((a, b) {
          final byDate = b.paymentDate.compareTo(a.paymentDate);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });

  bool _received(DividendPayment p) =>
      p.received &&
      !p.paymentDate.isAfter(DateTime(asOf.year, asOf.month, asOf.day));

  Map<String, int> receivedBySymbol(DividendPeriod period) {
    final totals = <String, int>{};
    for (final p in data.payments.where(
      (p) => _received(p) && period.contains(p.paymentDate, asOf),
    )) {
      totals.update(
        p.symbol,
        (amount) => amount + p.amountCents,
        ifAbsent: () => p.amountCents,
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) {
        final byAmount = b.value.compareTo(a.value);
        return byAmount != 0 ? byAmount : a.key.compareTo(b.key);
      });
    return Map.fromEntries(sorted);
  }

  int receivedTotal(DividendPeriod period) => payments(
    period,
  ).where(_received).fold(0, (sum, p) => sum + p.amountCents);
  int provisionedTotal(DividendPeriod period) => payments(
    period,
  ).where((p) => !p.received).fold(0, (sum, p) => sum + p.amountCents);

  List<DividendPayment> page(DividendPeriod period, int index) =>
      payments(period).skip(index * pageSize).take(pageSize).toList();

  List<DividendMonth> monthly(
    DividendPeriod period, {
    bool withReturns = false,
  }) {
    final received = data.payments.where(_received).toList();
    final valuations =
        data.valuations.where((v) => !v.date.isAfter(asOf)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final candidates = [
      for (final p in received) p.paymentDate,
      if (withReturns)
        for (final v in valuations) v.date,
    ];
    candidates.sort();
    final start =
        period.start(asOf) ?? (candidates.isEmpty ? asOf : candidates.first);
    final end = DateTime(asOf.year, asOf.month);
    final result = <DividendMonth>[];
    for (
      var month = DateTime(start.year, start.month);
      !month.isAfter(end);
      month = DateTime(month.year, month.month + 1)
    ) {
      final cash = received
          .where(
            (p) =>
                p.paymentDate.year == month.year &&
                p.paymentDate.month == month.month &&
                period.contains(p.paymentDate, asOf),
          )
          .fold<int>(0, (sum, p) => sum + p.amountCents);
      final snapshots = valuations
          .where(
            (v) =>
                v.date.year == month.year &&
                v.date.month == month.month &&
                period.contains(v.date, asOf),
          )
          .toList();
      final snapshot = snapshots.isEmpty ? null : snapshots.last;
      final allCash = snapshot == null
          ? 0
          : received
                .where((p) => !p.paymentDate.isAfter(snapshot.date))
                .fold<int>(0, (sum, p) => sum + p.amountCents);
      result.add(
        DividendMonth(
          month: month,
          receivedCents: cash,
          priceReturnPercent: snapshot == null
              ? null
              : (snapshot.marketValueCents - snapshot.investedCents) /
                    snapshot.investedCents *
                    100,
          totalReturnPercent: snapshot == null
              ? null
              : (snapshot.marketValueCents - snapshot.investedCents + allCash) /
                    snapshot.investedCents *
                    100,
        ),
      );
    }
    return result;
  }
}
