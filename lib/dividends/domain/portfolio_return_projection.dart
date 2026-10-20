import '../../portfolio/domain/asset_category.dart';
import '../../reports/domain/report_trade.dart';
import 'dividend_market_data.dart';
import 'dividend_payment.dart';
import 'dividend_repository.dart';

List<PortfolioValuation> projectPortfolioReturns(
  List<ReportTrade> trades,
  List<DividendPayment> payments,
  List<DividendMarketData> market,
  DateTime asOf,
  Set<String> warnings,
) {
  if (trades.isEmpty) return [];
  if (trades.any(
        (t) =>
            t.dateBasis != ReportDateBasis.trade ||
            t.category == AssetCategory.treasury,
      ) ||
      market.any(
        (m) =>
            m.hasCorporateActions ||
            (m.pricesUpdated && !m.announcementsUpdated),
      )) {
    warnings.add(
      'Rentabilidade histórica requer datas de negociação, preços originais de todos os ativos e tratamento dos eventos corporativos. Liquidações e Tesouro Direto não são estimados.',
    );
    return [];
  }
  final ordered = trades.where((t) => !t.date.isAfter(asOf)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  if (ordered.isEmpty) return [];
  if (payments.any(
    (p) => p.received && p.paymentDate.isBefore(ordered.first.date),
  )) {
    warnings.add(
      'Há proventos anteriores ao histórico de negociações. Importe o histórico completo para calcular a rentabilidade.',
    );
    return [];
  }
  final prices = {for (final item in market) item.symbol: item.closes};
  final dates = <String>{
    for (final item in market) ...item.closes.keys,
    for (final trade in ordered) trade.date.toIso8601String().substring(0, 10),
  }.toList()..sort();
  final quantities = <String, int>{};
  final result = <PortfolioValuation>[];
  var tradeIndex = 0;
  var invested = 0;
  var previousValue = 0;
  var priceFactor = 1.0;
  var totalFactor = 1.0;
  DateTime? previousDay;
  for (final key in dates) {
    final day = DateTime.parse(key);
    if (day.isBefore(ordered.first.date) || day.isAfter(asOf)) continue;
    var buys = 0;
    var sales = 0;
    while (tradeIndex < ordered.length &&
        !ordered[tradeIndex].date.isAfter(day)) {
      final trade = ordered[tradeIndex++];
      quantities.update(
        trade.symbol,
        (q) =>
            q +
            (trade.side == TradeSide.buy
                ? trade.quantityMicros
                : -trade.quantityMicros),
        ifAbsent: () => trade.side == TradeSide.buy
            ? trade.quantityMicros
            : -trade.quantityMicros,
      );
      if (trade.side == TradeSide.buy) {
        buys += trade.totalCents;
        invested += trade.totalCents;
      } else {
        sales += trade.totalCents;
      }
    }
    if (quantities.values.any((q) => q < 0) ||
        quantities.entries.any(
          (q) => q.value > 0 && prices[q.key]?[key] == null,
        )) {
      warnings.add(
        'Histórico de preços incompleto: as linhas não foram calculadas para evitar ligar períodos sem dados.',
      );
      return [];
    }
    final value = quantities.entries.fold<int>(
      0,
      (v, q) => v + (q.value * (prices[q.key]?[key] ?? 0) / 1000000).round(),
    );
    final cash = payments
        .where(
          (p) =>
              p.received &&
              !p.paymentDate.isAfter(day) &&
              (previousDay == null || p.paymentDate.isAfter(previousDay)),
        )
        .fold<int>(0, (v, p) => v + p.amountCents);
    final denominator = previousValue + buys;
    if (denominator <= 0) {
      if (cash > 0 || sales > 0) {
        warnings.add(
          'Há fluxos de caixa sem capital investido no período; a rentabilidade exige conciliação.',
        );
        return [];
      }
      continue;
    }
    // Daily time-weighted approximation: purchases at opening, sales at closing.
    priceFactor *= (value + sales) / denominator;
    totalFactor *= (value + sales + cash) / denominator;
    result.add(
      PortfolioValuation(
        date: day,
        investedCents: invested,
        marketValueCents: value,
        priceReturnPercent: (priceFactor - 1) * 100,
        totalReturnPercent: (totalFactor - 1) * 100,
      ),
    );
    previousValue = value;
    previousDay = day;
  }
  return result;
}
