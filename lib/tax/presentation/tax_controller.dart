import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../reports/domain/report_repository.dart';
import '../../reports/domain/report_trade.dart';
import '../data/tax_report_writer.dart';
import '../data/tax_rule_checker.dart';
import '../domain/tax_annual_report.dart';
import '../domain/tax_assessment.dart';
import '../domain/tax_month.dart';
import '../domain/tax_repository.dart';
import '../domain/tax_rule_status.dart';

class TaxController extends ChangeNotifier {
  TaxController(
    this.repository,
    this.reports,
    this.checker,
    this.writer, {
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final TaxRepository repository;
  final ReportRepository reports;
  final TaxRuleChecker checker;
  final TaxReportWriter writer;
  final DateTime Function() clock;
  late int year = clock().year;
  TaxYearData data = const TaxYearData(null, []);
  List<ReportTrade> trades = const [];
  TaxRuleStatus rules = const TaxRuleStatus();
  bool busy = false;
  bool checking = false;
  bool _disposed = false;
  Timer? _timer;
  String? error;
  String? exportedPath;

  List<TaxAssessment> get assessments =>
      assessTaxYear(data.opening, data.months);

  Future<void> initialize() async {
    try {
      rules = TaxRuleStatus.decode(await repository.loadCheckState());
    } catch (_) {
      error =
          'Não foi possível recuperar a última checagem. Verifique as fontes novamente.';
    }
    await loadYear(year);
    if (_disposed) return;
    unawaited(checkRules());
    _timer = Timer.periodic(
      const Duration(hours: 1),
      (_) => unawaited(checkRules()),
    );
  }

  Future<void> loadYear(int value) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _emit();
    try {
      final loaded = await repository.loadYear(value);
      final imported = await reports.listTrades();
      assessTaxYear(loaded.opening, loaded.months);
      year = value;
      data = loaded;
      trades = imported;
      exportedPath = null;
    } catch (_) {
      error = 'Não foi possível carregar os registros fiscais locais.';
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<bool> saveMonth(TaxMonth month) async =>
      _save(() => repository.saveMonth(month));
  Future<bool> saveOpening(TaxOpening opening) async =>
      _save(() => repository.saveOpening(opening));

  Future<bool> _save(Future<void> Function() action) async {
    if (busy || _disposed) return false;
    busy = true;
    _emit();
    try {
      await action();
      data = await repository.loadYear(year);
      error = null;
      exportedPath = null;
      return true;
    } catch (_) {
      error =
          'Não foi possível salvar. Verifique os valores e o acesso ao banco local.';
      return false;
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> checkRules({bool force = false}) async {
    if (checking || _disposed) return;
    checking = true;
    _emit();
    try {
      rules = await checker.check(rules, clock(), force: force);
      await repository.saveCheckState(rules.encode());
    } catch (_) {
      error =
          'A checagem não pôde ser salva. Os registros fiscais continuam disponíveis localmente.';
    } finally {
      checking = false;
      _emit();
    }
  }

  Future<void> exportAnnual() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _emit();
    try {
      final report = buildTaxAnnualReport(
        year: year,
        now: clock(),
        status: rules,
        opening: data.opening,
        months: data.months,
        trades: trades,
      );
      exportedPath = await writer.write(report, assessments);
    } on FormatException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Não foi possível gerar o demonstrativo na pasta de dados.';
    } finally {
      busy = false;
      _emit();
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
