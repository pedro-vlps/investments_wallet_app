import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'support/preview_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investments_wallet/dividends/domain/dividend_repository.dart';
import 'package:investments_wallet/dividends/presentation/dividend_controller.dart';
import 'package:investments_wallet/app/wallet_theme.dart';
import 'package:investments_wallet/app/portfolio_workspace.dart';
import 'package:investments_wallet/portfolio/domain/portfolio_position.dart';
import 'package:investments_wallet/portfolio/domain/portfolio_repository.dart';
import 'package:investments_wallet/portfolio/presentation/portfolio_controller.dart';
import 'package:investments_wallet/portfolio/presentation/position_table_column.dart';
import 'package:investments_wallet/portfolio/presentation/positions_table.dart';
import 'package:investments_wallet/quotes/domain/market_quote.dart';
import 'package:investments_wallet/quotes/domain/quote_provider.dart';

class _DemoRepository implements PortfolioRepository {
  @override
  Future<List<PortfolioPosition>> loadPositions() async {
    final demo =
        jsonDecode(File('assets/demo_portfolio.json').readAsStringSync())
            as Map<String, dynamic>;
    final quotes = (demo['quotes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return (demo['positions'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((p) {
          final q = quotes.singleWhere((q) => q['symbol'] == p['symbol']);
          return PortfolioPosition(
            symbol: p['symbol'] as String,
            company: p['company'] as String,
            quantity: p['quantity'] as int,
            averageCostCents: p['averageCostCents'] as int,
            dividendsReceivedCents: (demo['dividends'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .where((d) => d['symbol'] == p['symbol'])
                .fold<int>(0, (sum, d) => sum + (d['amountCents'] as int)),
            quote: MarketQuote(
              symbol: p['symbol'] as String,
              priceCents: q['priceCents'] as int,
              quotedAt: DateTime.parse(q['quotedAt'] as String),
              source: q['source'] as String,
            ),
          );
        })
        .toList();
  }

  @override
  Future<void> saveQuotes(List<MarketQuote> quotes) async {}

  @override
  Future<void> close() async {}
}

class _OfflineProvider implements QuoteProvider {
  @override
  Future<List<MarketQuote>> fetchQuotes(List<String> symbols) async =>
      throw const QuoteException('Sem conexão.');
}

class _EmptyDividendRepository implements DividendRepository {
  @override
  Future<DividendData> loadData() async =>
      const DividendData(payments: [], valuations: []);
}

void main() {
  setUpAll(loadPreviewFonts);
  for (final width in [1440.0, 390.0]) {
    testWidgets('dark portfolio and offline refresh at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = PortfolioController(
        _DemoRepository(),
        _OfflineProvider(),
      );
      addTearDown(controller.dispose);
      await controller.load();
      final dividendController = DividendController(_EmptyDividendRepository());
      addTearDown(dividendController.dispose);
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildWalletTheme(),
          home: RepaintBoundary(
            key: captureKey,
            child: PortfolioWorkspace(
              controller: controller,
              dividendController: dividendController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Minha carteira'), findsOneWidget);
      expect(find.text('PETR4'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Minha carteira'))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);

      if (width == 1440) {
        await tester.tap(find.byTooltip('Recolher menu'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
          false,
        );
        expect(find.text('Minha carteira'), findsOneWidget);
        await tester.tap(find.byTooltip('Expandir menu'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
          true,
        );
      }
      await tester.tap(find.byIcon(Icons.table_chart_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Carteira detalhada'), findsOneWidget);
      expect(
        tester.widget<DataTable>(find.byType(DataTable)).columns.length,
        PositionTableColumn.values.length,
      );
      expect(tester.takeException(), isNull);

      for (final column in PositionTableColumn.values) {
        final header = find.text(column.label);
        await tester.ensureVisible(header);
        await tester.pumpAndSettle();
        await tester.tap(header);
        await tester.pumpAndSettle();
        final table = tester.widget<DataTable>(find.byType(DataTable));
        expect(table.sortColumnIndex, column.index);
        expect(
          table.sortAscending,
          column == PositionTableColumn.symbol ? false : true,
        );
        expect(
          table.rows.map((row) => (row.key! as ValueKey<String>).value),
          sortPositions(
            controller.positions,
            column,
            ascending: table.sortAscending,
          ).map((p) => p.symbol),
        );
        await tester.tap(header);
        await tester.pumpAndSettle();
        expect(
          tester.widget<DataTable>(find.byType(DataTable)).sortAscending,
          column == PositionTableColumn.symbol ? true : false,
        );
      }

      // Capture the initial columns, after exercising all sortable headers.
      await tester.ensureVisible(find.text('ATIVO'));
      await tester.pumpAndSettle();

      if (width == 1440 && const bool.fromEnvironment('CAPTURE_PREVIEW')) {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File(
            'build/portfolio-detailed-preview.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.ensureVisible(find.text('Atualizar cotações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atualizar cotações'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Os dados salvos foram mantidos'),
        findsOneWidget,
      );
      expect(find.text('PETR4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'rendered price and accumulated returns use green, red, or neutral text',
    (tester) async {
      final positions = [
        for (final entry in {
          'POSI3': 3000,
          'NEGA3': 2000,
          'ZERO3': 2500,
        }.entries)
          PortfolioPosition(
            symbol: entry.key,
            company: entry.key,
            quantity: 1,
            averageCostCents: 2500,
            quote: MarketQuote(
              symbol: entry.key,
              priceCents: entry.value,
              quotedAt: DateTime.utc(2026),
              source: 'test',
            ),
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildWalletTheme(),
          home: Scaffold(
            body: PositionsTable(positions: positions, detailed: true),
          ),
        ),
      );
      for (final entry in <String, Color?>{
        'POSI3': WalletColors.accent,
        'NEGA3': WalletColors.loss,
        'ZERO3': null,
      }.entries) {
        for (final column in [
          'gain',
          'gainPercent',
          'totalGain',
          'totalGainPercent',
        ]) {
          final text = tester.widget<Text>(
            find.byKey(ValueKey('${entry.key}-$column')),
          );
          expect(text.style?.color, entry.value);
        }
      }
      expect(tester.takeException(), isNull);
    },
  );
}
