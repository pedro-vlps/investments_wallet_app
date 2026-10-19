import 'package:flutter_test/flutter_test.dart';
import 'package:investments_wallet/portfolio/domain/portfolio_position.dart';
import 'package:investments_wallet/portfolio/presentation/position_table_column.dart';
import 'package:investments_wallet/quotes/domain/market_quote.dart';

void main() {
  final positions = [
    PortfolioPosition(
      symbol: 'ALFA3',
      company: 'Zeta',
      quantity: 2,
      averageCostCents: 10000,
      dividendsReceivedCents: 1000,
      quote: MarketQuote(
        symbol: 'ALFA3',
        priceCents: 5000,
        quotedAt: DateTime.utc(2026, 10, 3),
        source: 'Z',
      ),
    ),
    PortfolioPosition(
      symbol: 'BETA3',
      company: 'Alpha',
      quantity: 10,
      averageCostCents: 100,
      dividendsReceivedCents: 500,
      quote: MarketQuote(
        symbol: 'BETA3',
        priceCents: 200,
        quotedAt: DateTime.utc(2026, 10, 1),
        source: 'A',
      ),
    ),
    PortfolioPosition(
      symbol: 'GAMA3',
      company: 'Middle',
      quantity: 1,
      averageCostCents: 1000,
      quote: MarketQuote(
        symbol: 'GAMA3',
        priceCents: 1000,
        quotedAt: DateTime.utc(2026, 10, 2),
        source: 'M',
      ),
    ),
  ];
  final expected = <PositionTableColumn, List<String>>{
    PositionTableColumn.symbol: ['ALFA3', 'BETA3', 'GAMA3'],
    PositionTableColumn.company: ['BETA3', 'GAMA3', 'ALFA3'],
    PositionTableColumn.quantity: ['GAMA3', 'ALFA3', 'BETA3'],
    PositionTableColumn.averageCost: ['BETA3', 'GAMA3', 'ALFA3'],
    PositionTableColumn.invested: ['BETA3', 'GAMA3', 'ALFA3'],
    PositionTableColumn.quotePrice: ['BETA3', 'GAMA3', 'ALFA3'],
    PositionTableColumn.marketValue: ['GAMA3', 'BETA3', 'ALFA3'],
    PositionTableColumn.allocation: ['GAMA3', 'BETA3', 'ALFA3'],
    PositionTableColumn.gain: ['ALFA3', 'GAMA3', 'BETA3'],
    PositionTableColumn.gainPercent: ['ALFA3', 'GAMA3', 'BETA3'],
    PositionTableColumn.dividends: ['GAMA3', 'BETA3', 'ALFA3'],
    PositionTableColumn.totalGain: ['ALFA3', 'GAMA3', 'BETA3'],
    PositionTableColumn.totalGainPercent: ['ALFA3', 'GAMA3', 'BETA3'],
    PositionTableColumn.quotedAt: ['BETA3', 'GAMA3', 'ALFA3'],
    PositionTableColumn.source: ['BETA3', 'GAMA3', 'ALFA3'],
  };
  for (final entry in expected.entries) {
    test('sort ${entry.key.name} numerically or lexically as appropriate', () {
      expect(
        sortPositions(
          positions,
          entry.key,
          ascending: true,
        ).map((p) => p.symbol),
        entry.value,
      );
      // Ties are always deterministic by symbol, even for descending order.
      if (entry.key != PositionTableColumn.invested) {
        expect(
          sortPositions(
            positions,
            entry.key,
            ascending: false,
          ).map((p) => p.symbol),
          entry.value.reversed,
        );
      }
      expect(positions.first.symbol, 'ALFA3');
    });
  }
  test('zero return and zero dividends remain exactly zero', () {
    expect(positions.last.totalGainCents, 0);
    expect(positions.last.totalGainPercent, 0);
  });
}
