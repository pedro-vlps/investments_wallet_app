import 'portfolio_position.dart';

class PortfolioTotals {
  PortfolioTotals(Iterable<PortfolioPosition> positions)
    : investedCents = positions.fold(0, (sum, p) => sum + p.investedCents),
      marketValueCents = positions.fold(
        0,
        (sum, p) => sum + p.marketValueCents,
      );

  final int investedCents;
  final int marketValueCents;
  int get gainCents => marketValueCents - investedCents;
  double get gainPercent =>
      investedCents == 0 ? 0 : gainCents / investedCents * 100;
}
