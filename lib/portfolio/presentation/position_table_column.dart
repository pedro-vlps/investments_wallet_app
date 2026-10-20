import '../domain/portfolio_position.dart';

enum PositionTableColumn {
  symbol('ATIVO'),
  quantity('QUANTIDADE', numeric: true, detailedOnly: true),
  averageCost('PREÇO MÉDIO', numeric: true, detailedOnly: true),
  invested('TOTAL INVESTIDO', numeric: true, detailedOnly: true),
  quotePrice('ÚLTIMA COTAÇÃO', numeric: true, detailedOnly: true),
  marketValue('VALOR ATUAL', numeric: true, detailedOnly: true),
  allocation('POSIÇÃO (%)', numeric: true, detailedOnly: true),
  gain('RESULTADO (R\$)', numeric: true),
  gainPercent('RESULTADO (%)', numeric: true);

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
    quantity => a.quantity.compareTo(b.quantity),
    averageCost => a.averageCostCents.compareTo(b.averageCostCents),
    invested => a.investedCents.compareTo(b.investedCents),
    quotePrice => a.quote.priceCents.compareTo(b.quote.priceCents),
    // Allocation has the same positive portfolio denominator for every row.
    marketValue ||
    allocation => a.marketValueCents.compareTo(b.marketValueCents),
    gain => a.unrealizedGainCents.compareTo(b.unrealizedGainCents),
    gainPercent => a.unrealizedGainPercent.compareTo(b.unrealizedGainPercent),
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
