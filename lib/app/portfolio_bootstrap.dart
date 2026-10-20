import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../dividends/data/sqlite_dividend_repository.dart';
import '../dividends/presentation/dividend_controller.dart';
import '../dividends/data/brapi_dividend_provider.dart';
import '../dividends/data/dividend_synchronizer.dart';
import '../app_storage/open_wallet_storage.dart';
import '../reports/data/sqlite_report_repository.dart';
import '../reports/presentation/report_controller.dart';
import '../tax/data/sqlite_tax_repository.dart';
import '../tax/data/tax_report_writer.dart';
import '../tax/data/tax_rule_checker.dart';
import '../tax/presentation/tax_controller.dart';

import '../portfolio/data/sqlite_portfolio_repository.dart';
import '../portfolio/presentation/portfolio_controller.dart';
import '../quotes/data/brapi_quote_provider.dart';
import '../quotes/data/secure_quote_credentials.dart';
import '../quotes/presentation/quote_settings_dialog.dart';
import 'portfolio_workspace.dart';

class PortfolioBootstrap extends StatefulWidget {
  const PortfolioBootstrap({super.key});

  @override
  State<PortfolioBootstrap> createState() => _PortfolioBootstrapState();
}

class _PortfolioBootstrapState extends State<PortfolioBootstrap> {
  final _client = http.Client();
  PortfolioController? _controller;
  DividendController? _dividendController;
  ReportController? _reportController;
  TaxController? _taxController;
  SqlitePortfolioRepository? _repository;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    setState(() => _failed = false);
    try {
      final storage = await openWalletStorage();
      final repository = SqlitePortfolioRepository(storage.databasePath);
      await repository.initialize();
      if (!mounted) return;
      final controller = PortfolioController(
        repository,
        BrapiQuoteProvider(
          _client,
          credentials: const SecureQuoteCredentials(),
        ),
      );
      _repository = repository;
      _controller = controller;
      final dividendController = DividendController(
        SqliteDividendRepository(repository.databasePath),
      );
      _dividendController = dividendController;
      final reportRepository = SqliteReportRepository(
        storage.databasePath,
        storage.reportDirectory,
      );
      dividendController.synchronizeMarket = DividendSynchronizer(
        storage.databasePath,
        reportRepository,
        BrapiDividendProvider(_client, const SecureQuoteCredentials()),
      ).synchronize;
      final taxController = TaxController(
        SqliteTaxRepository(storage.databasePath),
        reportRepository,
        TaxRuleChecker(_client),
        TaxReportWriter(storage.directory),
      );
      _taxController = taxController;
      final reportController = ReportController(
        reportRepository,
        dataDirectory: storage.directory,
        onImported: () async {
          await Future.wait([
            controller.load(),
            dividendController.load(),
            taxController.loadYear(taxController.year),
          ]);
          unawaited(dividendController.synchronize());
        },
      );
      _reportController = reportController;
      await reportController.load();
      await Future.wait([
        controller.load(),
        dividendController.load(),
        taxController.initialize(),
      ]);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _dividendController?.dispose();
    _reportController?.dispose();
    _taxController?.dispose();
    _client.close();
    final repository = _repository;
    if (repository != null) unawaited(repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller case final controller?) {
      return PortfolioWorkspace(
        controller: controller,
        dividendController: _dividendController!,
        reportController: _reportController!,
        taxController: _taxController!,
        onConfigureQuotes: () => showDialog<void>(
          context: context,
          builder: (_) =>
              const QuoteSettingsDialog(credentials: SecureQuoteCredentials()),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: _failed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Não foi possível abrir o banco local. Verifique o acesso à pasta de dados.',
                    ),
                  ),
                  FilledButton(
                    onPressed: _initialize,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            : const CircularProgressIndicator(
                semanticsLabel: 'Preparando banco local',
              ),
      ),
    );
  }
}
