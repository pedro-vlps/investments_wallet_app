import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investments_wallet/portfolio/data/sqlite_portfolio_repository.dart';
import 'package:investments_wallet/portfolio/domain/portfolio_totals.dart';
import 'package:investments_wallet/portfolio/presentation/portfolio_controller.dart';
import 'package:investments_wallet/quotes/domain/market_quote.dart';
import 'package:investments_wallet/quotes/domain/quote_provider.dart';

class _Quotes implements QuoteProvider {
  int calls = 0;
  bool fail = false;

  @override
  Future<List<MarketQuote>> fetchQuotes(List<String> symbols) async {
    calls++;
    await Future<void>.delayed(Duration.zero);
    if (fail) throw const QuoteException('Sem conexão.');
    return symbols
        .map(
          (symbol) => MarketQuote(
            symbol: symbol,
            priceCents: 7000,
            quotedAt: DateTime.utc(2026, 10, 18),
            source: 'test',
          ),
        )
        .toList();
  }
}

void main() {
  late Directory directory;
  late SqlitePortfolioRepository repository;
  late String demo;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('wallet_test_');
    repository = SqlitePortfolioRepository(
      '${directory.path}/portfolio.sqlite3',
    );
    demo = await File('assets/demo_portfolio.json').readAsString();
    await repository.initialize(demo);
  });

  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('demo totals use exact cents and include losses', () async {
    final positions = await repository.loadPositions();
    final totals = PortfolioTotals(positions);
    expect(positions.length, 3);
    expect(totals.investedCents, 1724500);
    expect(totals.marketValueCents, 1847830);
    expect(totals.gainCents, 123330);
    expect(
      positions.singleWhere((p) => p.symbol == 'VALE3').unrealizedGainCents,
      -22320,
    );
    expect(PortfolioTotals([]).gainPercent, 0);
  });

  test('reopening never reseeds or replaces newer saved prices', () async {
    await repository.saveQuotes([
      MarketQuote(
        symbol: 'PETR4',
        priceCents: 6100,
        quotedAt: DateTime.utc(2026, 10, 18),
        source: 'test',
      ),
    ]);
    final reopened = SqlitePortfolioRepository(repository.databasePath);
    await reopened.initialize(demo);
    await reopened.saveQuotes([
      MarketQuote(
        symbol: 'PETR4',
        priceCents: 100,
        quotedAt: DateTime.utc(2020),
        source: 'stale',
      ),
    ]);
    expect(
      (await reopened.loadPositions())
          .singleWhere((p) => p.symbol == 'PETR4')
          .quote
          .priceCents,
      6100,
    );
  });

  test('a rejected quote rolls back the entire SQLite update', () async {
    await expectLater(
      repository.saveQuotes([
        MarketQuote(
          symbol: 'PETR4',
          priceCents: 9999,
          quotedAt: DateTime.utc(2026, 10, 18),
          source: 'test',
        ),
        MarketQuote(
          symbol: 'XXXX3',
          priceCents: 9999,
          quotedAt: DateTime.utc(2026, 10, 18),
          source: 'test',
        ),
      ]),
      throwsA(isA<Exception>()),
    );
    expect(
      (await repository.loadPositions())
          .singleWhere((p) => p.symbol == 'PETR4')
          .quote
          .priceCents,
      5968,
    );
  });

  test('offline failure preserves loaded and persisted prices', () async {
    final provider = _Quotes()..fail = true;
    final controller = PortfolioController(repository, provider);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.synchronize();
    expect(controller.error, contains('Os dados salvos foram mantidos'));
    expect(
      controller.positions
          .singleWhere((p) => p.symbol == 'PETR4')
          .quote
          .priceCents,
      5968,
    );
    expect(
      (await repository.loadPositions())
          .singleWhere((p) => p.symbol == 'PETR4')
          .quote
          .priceCents,
      5968,
    );
    expect(controller.syncing, false);
  });

  test('duplicate sync clicks produce only one update', () async {
    final provider = _Quotes();
    final controller = PortfolioController(repository, provider);
    addTearDown(controller.dispose);
    await controller.load();
    await Future.wait([controller.synchronize(), controller.synchronize()]);
    expect(provider.calls, 1);
    expect(controller.positions.every((p) => p.quote.priceCents == 7000), true);
    expect(controller.notice, isNotNull);
  });
}
