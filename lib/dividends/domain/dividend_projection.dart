import '../../reports/domain/report_trade.dart';
import 'dividend_market_data.dart';
import 'dividend_payment.dart';
import 'dividend_repository.dart';
import 'portfolio_return_projection.dart';

DividendData projectDividends({
  required List<ReportTrade> trades,
  required List<DividendPayment> received,
  required List<DividendMarketData> market,
  required DateTime asOf,
}) {
  final warnings = <String>{for (final item in market) ...item.warnings};
  final today = DateTime(asOf.year, asOf.month, asOf.day);
  final announcements = [for (final item in market) ...item.announcements];
  final payments = received.map((payment) {
    final matches = announcements
        .where(
          (a) =>
              a.symbol == payment.symbol &&
              a.kind == payment.kind &&
              a.paymentDate == payment.paymentDate,
        )
        .toList();
    if (matches.length != 1) return payment;
    final announcement = matches.single;
    return DividendPayment(
      id: payment.id,
      symbol: payment.symbol,
      amountCents: payment.amountCents,
      paymentDate: payment.paymentDate,
      received: payment.received,
      kind: payment.kind,
      perShareMicros: payment.perShareMicros,
      eligibleQuantity: payment.eligibleQuantity,
      cumDate: payment.cumDate ?? announcement.cumDate,
      exDate: payment.exDate ?? announcement.exDate,
      estimated: payment.estimated,
    );
  }).toList();
  final seen = <String>{};
  for (final item in market) {
    final history = trades.where((t) => t.symbol == item.symbol).toList();
    if (history.isEmpty) continue;
    final reliable =
        history.every((t) => t.dateBasis == ReportDateBasis.trade) &&
        !item.hasCorporateActions &&
        item.announcementsUpdated;
    if (!reliable) {
      warnings.add(
        '${item.symbol}: previsão depende de datas de negociação e histórico de eventos corporativos completos. Recebimentos do relatório foram preservados.',
      );
    }
    for (final announcement in item.announcements) {
      final key =
          '${item.symbol}-${announcement.kind.name}-${announcement.cumDate}-${announcement.paymentDate}-${announcement.perShareMicros}';
      if (!seen.add(key)) continue;
      final matches = payments
          .where(
            (p) =>
                p.received &&
                p.symbol == item.symbol &&
                p.kind == announcement.kind &&
                p.paymentDate == announcement.paymentDate,
          )
          .toList();
      if (matches.isNotEmpty) {
        continue; // Custodian credits always win over estimates.
      }
      if (!reliable || announcement.cumDate.isAfter(today)) continue;
      final quantity = history
          .where((t) => !t.date.isAfter(announcement.cumDate))
          .fold<int>(
            0,
            (q, t) =>
                q +
                (t.side == TradeSide.buy
                    ? t.quantityMicros
                    : -t.quantityMicros),
          );
      if (quantity <= 0 || quantity % 1000000 != 0) continue;
      final shares = quantity ~/ 1000000;
      final amount = (shares * announcement.perShareMicros / 10000).round();
      if (amount <= 0) continue;
      payments.add(
        DividendPayment(
          id: 'estimated-$key',
          symbol: item.symbol,
          amountCents: amount,
          paymentDate: announcement.paymentDate,
          received: false,
          kind: announcement.kind,
          perShareMicros: announcement.perShareMicros,
          eligibleQuantity: shares,
          cumDate: announcement.cumDate,
          exDate: announcement.exDate,
          estimated: true,
        ),
      );
    }
  }
  final valuations = projectPortfolioReturns(
    trades,
    received,
    market,
    today,
    warnings,
  );
  final checks = market.map((m) => m.checkedAt).toList()..sort();
  return DividendData(
    payments: payments,
    valuations: valuations,
    demo: false,
    warnings: warnings.toList(),
    checkedAt: checks.isEmpty ? null : checks.last,
    announcements: announcements,
  );
}
