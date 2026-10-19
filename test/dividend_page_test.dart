import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:investments_wallet/app/portfolio_workspace.dart';
import 'package:investments_wallet/app/wallet_theme.dart';
import 'package:investments_wallet/dividends/data/sqlite_dividend_repository.dart';
import 'package:investments_wallet/dividends/domain/dividend_period.dart';
import 'package:investments_wallet/dividends/domain/dividend_repository.dart';
import 'package:investments_wallet/dividends/presentation/dividend_controller.dart';
import 'package:investments_wallet/dividends/presentation/dividend_page.dart';
import 'package:investments_wallet/dividends/presentation/monthly_dividend_chart.dart';
import 'package:investments_wallet/dividends/presentation/portfolio_return_chart.dart';
import 'package:investments_wallet/portfolio/data/sqlite_portfolio_repository.dart';
import 'package:investments_wallet/portfolio/presentation/portfolio_controller.dart';
import 'package:investments_wallet/quotes/domain/market_quote.dart';
import 'package:investments_wallet/quotes/domain/quote_provider.dart';

import 'support/preview_fonts.dart';

class _OfflineQuotes implements QuoteProvider {
  @override
  Future<List<MarketQuote>> fetchQuotes(List<String> symbols) async =>
      throw const QuoteException('Offline');
}

class _RetryRepository implements DividendRepository {
  bool fail = true;
  @override
  Future<DividendData> loadData() async {
    if (fail) throw StateError('Unavailable');
    return const DividendData(payments: [], valuations: []);
  }
}

Finder picker(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(DropdownButton<DividendPeriod>),
);

Future<void> choose(
  WidgetTester tester,
  String key,
  DividendPeriod period,
) async {
  await tester.ensureVisible(picker(key));
  await tester.pumpAndSettle();
  await tester.tap(picker(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text(period.label).last);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PREVIEW')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build').create(recursive: true);
    await File('build/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  late Directory directory;
  late DividendController dividends;
  late PortfolioController portfolio;
  setUpAll(loadPreviewFonts);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dividend_ui_');
    final repository = SqlitePortfolioRepository(
      '${directory.path}/wallet.sqlite3',
    );
    await repository.initialize(
      await File('assets/demo_portfolio.json').readAsString(),
    );
    portfolio = PortfolioController(repository, _OfflineQuotes());
    dividends = DividendController(
      SqliteDividendRepository(repository.databasePath),
      now: () => DateTime(2026, 10, 18),
    );
    await Future.wait([portfolio.load(), dividends.load()]);
  });
  tearDown(() async {
    portfolio.dispose();
    dividends.dispose();
    await directory.delete(recursive: true);
  });

  for (final width in [1440.0, 390.0]) {
    testWidgets(
      'dividend navigation, independent periods, and ten-row pages at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildWalletTheme(),
            home: RepaintBoundary(
              key: key,
              child: PortfolioWorkspace(
                controller: portfolio,
                dividendController: dividends,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.payments_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Dividendos recebidos'), findsOneWidget);
        expect(find.text('Dividendos totais'), findsOneWidget);
        expect(find.text('Todos os dividendos'), findsOneWidget);
        for (final name in [
          'received-period',
          'total-period',
          'events-period',
        ]) {
          expect(
            tester.widget<DropdownButton<DividendPeriod>>(picker(name)).value,
            DividendPeriod.inception,
          );
        }
        expect(
          tester
              .widget<DropdownButton<DividendPeriod>>(picker('total-period'))
              .items!
              .length,
          7,
        );
        expect(
          tester
              .widget<DropdownButton<DividendPeriod>>(picker('received-period'))
              .items!
              .length,
          5,
        );
        final table = find.byKey(const ValueKey('dividend-events-table'));
        expect(tester.widget<DataTable>(table).rows.length, 10);
        await tester.ensureVisible(find.byTooltip('Próxima página'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Próxima página'));
        await tester.pumpAndSettle();
        expect(find.text('Página 2 de 3 · 26 lançamentos'), findsOneWidget);

        await choose(tester, 'events-period', DividendPeriod.month);
        expect(tester.widget<DataTable>(table).rows.length, 3);
        expect(find.text('Página 1 de 1 · 3 lançamentos'), findsOneWidget);
        expect(
          tester
              .widget<DropdownButton<DividendPeriod>>(picker('received-period'))
              .value,
          DividendPeriod.inception,
        );
        await choose(tester, 'received-period', DividendPeriod.month);
        expect(
          tester
              .widget<DropdownButton<DividendPeriod>>(picker('total-period'))
              .value,
          DividendPeriod.inception,
        );
        await choose(tester, 'total-period', DividendPeriod.fiveYears);
        expect(
          tester
              .widget<MonthlyDividendChart>(find.byType(MonthlyDividendChart))
              .months
              .length,
          2,
        );
        final returns = find.byType(PortfolioReturnChart);
        expect(tester.widget<PortfolioReturnChart>(returns).months.length, 61);
        expect(
          find.descendant(of: returns, matching: find.byType(Scrollable)),
          findsNothing,
        );
        expect(
          find.descendant(of: returns, matching: find.byType(BarChart)),
          findsNothing,
        );
        final line = tester.widget<LineChart>(
          find.descendant(of: returns, matching: find.byType(LineChart)),
        );
        expect(line.data.lineBarsData.length, 2);
        expect(
          line.data.lineBarsData.every((series) => series.spots.length == 61),
          true,
        );
        final plot = find.byKey(const ValueKey('portfolio-return-plot'));
        expect(
          tester.getSize(plot).width,
          lessThanOrEqualTo(tester.getSize(returns).width),
        );
        expect(tester.getSize(returns).width, lessThan(width));
        expect(
          find.descendant(of: returns, matching: find.text('10/21')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: returns, matching: find.text('10/26')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        if (width == 1440) {
          await choose(tester, 'received-period', DividendPeriod.year);
          await choose(tester, 'total-period', DividendPeriod.year);
          await choose(tester, 'events-period', DividendPeriod.inception);
          await tester.ensureVisible(
            find.byKey(const ValueKey('dividends-title')),
          );
          await tester.pumpAndSettle();
          await capture(tester, key, 'dividends-preview');
          await tester.ensureVisible(find.byTooltip('Próxima página'));
          await tester.pumpAndSettle();
          await capture(tester, key, 'dividends-table-preview');
          await tester.tap(find.byIcon(Icons.dashboard_outlined));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.payments_outlined));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<DropdownButton<DividendPeriod>>(
                  picker('received-period'),
                )
                .value,
            DividendPeriod.year,
          );
        }
      },
    );
  }

  testWidgets('empty data and failed local reads offer a working retry', (
    tester,
  ) async {
    final repository = _RetryRepository();
    final controller = DividendController(
      repository,
      now: () => DateTime(2026, 10, 18),
    );
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWalletTheme(),
        home: Scaffold(body: DividendPage(controller: controller)),
      ),
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum dividendo recebido no período.'), findsOneWidget);
    expect(
      find.text('Nenhum dividendo no período selecionado.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
