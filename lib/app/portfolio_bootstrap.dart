import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../dividends/data/sqlite_dividend_repository.dart';
import '../dividends/presentation/dividend_controller.dart';
import '../app_storage/open_wallet_storage.dart';
import '../reports/data/sqlite_report_repository.dart';
import '../reports/presentation/report_controller.dart';

import '../portfolio/data/sqlite_portfolio_repository.dart';
import '../portfolio/presentation/portfolio_controller.dart';
import '../quotes/data/brapi_quote_provider.dart';
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
        BrapiQuoteProvider(_client),
      );
      _repository = repository;
      _controller = controller;
      final dividendController = DividendController(
        SqliteDividendRepository(repository.databasePath),
      );
      _dividendController = dividendController;
      final reportController = ReportController(
        SqliteReportRepository(storage.databasePath, storage.reportDirectory),
        dataDirectory: storage.directory,
        onImported: () async {
          await Future.wait([controller.load(), dividendController.load()]);
        },
      );
      _reportController = reportController;
      await Future.wait([
        controller.load(),
        dividendController.load(),
        reportController.load(),
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
