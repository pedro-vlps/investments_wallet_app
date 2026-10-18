import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investments_wallet/app/wallet_theme.dart';
import 'package:investments_wallet/portfolio/domain/portfolio_position.dart';
import 'package:investments_wallet/portfolio/domain/portfolio_repository.dart';
import 'package:investments_wallet/portfolio/presentation/portfolio_controller.dart';
import 'package:investments_wallet/portfolio/presentation/portfolio_page.dart';
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

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_PREVIEW')) {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Use SDK fonts for a readable, reproducible headless preview.
      for (final font in {
        'Segoe UI': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf',
      }.entries) {
        final loader = FontLoader(font.key);
        final bytes = File(
          '.tools/flutter/bin/cache/artifacts/material_fonts/${font.value}',
        ).readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    }
  });
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
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildWalletTheme(),
          home: RepaintBoundary(
            key: captureKey,
            child: PortfolioPage(controller: controller),
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

      if (width == 1440 && const bool.fromEnvironment('CAPTURE_PREVIEW')) {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File(
            'build/portfolio-preview.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

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
}
