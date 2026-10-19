import '../domain/portfolio_position.dart';

enum PositionTableColumn {
  symbol('ATIVO'),
  company('EMPRESA'),
  quantity('QUANTIDADE', numeric: true),
  averageCost('PREÇO MÉDIO', numeric: true),
  invested('TOTAL INVESTIDO', numeric: true, detailedOnly: true),
  quotePrice('ÚLTIMA COTAÇÃO', numeric: true),
  marketValue('VALOR ATUAL', numeric: true),
  allocation('POSIÇÃO (%)', numeric: true, detailedOnly: true),
  gain('RESULTADO (R\$)', numeric: true),
  gainPercent('RENTABILIDADE (%)', numeric: true),
  dividends('DIVIDENDOS RECEBIDOS', numeric: true, detailedOnly: true),
  totalGain('ACUMULADO (R\$)', numeric: true, detailedOnly: true),
  totalGainPercent('ACUMULADA (%)', numeric: true, detailedOnly: true),
  quotedAt('COTAÇÃO EM'),
  source('FONTE');

  const PositionTableColumn(
    this.label, {
    this.numeric = false,
    this.detailedOnly = false,
  });
  final String label;
  final bool numeric;
  final bool detailedOnly;

  int compare(PortfolioPosition a, PortfolioPosition b) => switch (this) {
    symbol => a.symbol.compareTo(b.symbol),
    company => a.company.toLowerCase().compareTo(b.company.toLowerCase()),
    quantity => a.quantity.compareTo(b.quantity),
    averageCost => a.averageCostCents.compareTo(b.averageCostCents),
    invested => a.investedCents.compareTo(b.investedCents),
    quotePrice => a.quote.priceCents.compareTo(b.quote.priceCents),
    // Allocation has the same positive portfolio denominator for every row.
    marketValue ||
    allocation => a.marketValueCents.compareTo(b.marketValueCents),
    gain => a.unrealizedGainCents.compareTo(b.unrealizedGainCents),
    gainPercent => a.unrealizedGainPercent.compareTo(b.unrealizedGainPercent),
    dividends => a.dividendsReceivedCents.compareTo(b.dividendsReceivedCents),
    totalGain => a.totalGainCents.compareTo(b.totalGainCents),
    totalGainPercent => a.totalGainPercent.compareTo(b.totalGainPercent),
    quotedAt => a.quote.quotedAt.compareTo(b.quote.quotedAt),
    source => a.quote.source.compareTo(b.quote.source),
  };
}

List<PortfolioPosition> sortPositions(
  Iterable<PortfolioPosition> positions,
  PositionTableColumn column, {
  required bool ascending,
}) {
  return positions.toList()..sort((a, b) {
    final result = column.compare(a, b);
    if (result == 0) return a.symbol.compareTo(b.symbol);
    return ascending ? result : -result;
  });
}
