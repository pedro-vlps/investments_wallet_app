import 'dart:isolate';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import '../../portfolio/domain/asset_category.dart';
import '../data/b3_report_parser.dart';
import '../data/report_file_picker.dart';
import '../domain/report_document.dart';
import '../domain/report_repository.dart';
import '../domain/report_trade.dart';

class ReportController extends ChangeNotifier {
  ReportController(
    this._repository, {
    required this.dataDirectory,
    this.onImported,
    this.pickFile,
  });
  final ReportRepository _repository;
  final String dataDirectory;
  final Future<void> Function()? onImported;
  final Future<XFile?> Function()? pickFile;
  List<StoredReport> reports = const [];
  ParsedReport? preview;
  String? fileName;
  Uint8List? _bytes;
  bool busy = false;
  bool _disposed = false;
  String? error;
  String? notice;
  final classifications = <String, AssetCategory>{};
  final excludedSymbols = <String>{};

  bool get canImport =>
      !busy &&
      preview != null &&
      preview!.trades.any((t) => !excludedSymbols.contains(t.symbol)) &&
      preview!.trades.every(
        (t) =>
            excludedSymbols.contains(t.symbol) ||
            t.category != null ||
            classifications.containsKey(t.symbol),
      );

  Future<void> load() async {
    if (busy) return;
    busy = true;
    error = null;
    _emit();
    try {
      reports = await _repository.listReports();
    } catch (_) {
      error = 'Não foi possível ler os relatórios locais. Tente novamente.';
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> selectFile() async {
    if (busy) return;
    busy = true;
    error = null;
    notice = null;
    _emit();
    var choosingFile = true;
    try {
      final selected = await (pickFile?.call() ?? pickReportFile());
      if (selected == null) return;
      choosingFile = false;
      preview = null;
      _bytes = null;
      fileName = null;
      classifications.clear();
      excludedSymbols.clear();
      if (await selected.length() > B3ReportParser.maxBytes) {
        throw const ReportImportException('O arquivo deve ter até 10 MB.');
      }
      final bytes = await selected.readAsBytes();
      final name = selected.name;
      final parsed = await Isolate.run(
        () => B3ReportParser().parse(name, bytes),
      );
      _bytes = bytes;
      fileName = name;
      preview = parsed;
    } on ReportImportException catch (failure) {
      error = failure.message;
    } catch (_) {
      error = choosingFile
          ? 'Não foi possível abrir a janela de seleção de arquivos. Feche o aplicativo, abra novamente e tente selecionar o relatório.'
          : 'Não foi possível abrir o arquivo selecionado. Verifique o acesso ao arquivo.';
    } finally {
      busy = false;
      _emit();
    }
  }

  void classify(String symbol, AssetCategory? category) {
    if (busy) return;
    if (category == null) {
      excludedSymbols.add(symbol);
      classifications.remove(symbol);
    } else {
      excludedSymbols.remove(symbol);
      classifications[symbol] = category;
    }
    _emit();
  }

  Future<void> importSelected() async {
    if (!canImport) return;
    busy = true;
    error = null;
    notice = null;
    _emit();
    var saved = false;
    try {
      final source = preview!;
      final trades = source.trades
          .where((t) => !excludedSymbols.contains(t.symbol))
          .map((t) => t.classified(t.category ?? classifications[t.symbol]!))
          .toList();
      await _repository.importReport(
        name: fileName!,
        bytes: _bytes!,
        report: ParsedReport(
          trades: trades,
          issues: [
            ...source.issues,
            for (final t in source.trades.where(
              (t) => excludedSymbols.contains(t.symbol),
            ))
              ReportIssue(
                t.location,
                'Ativo ignorado na revisão: ${t.symbol}.',
              ),
          ],
          layouts: source.layouts,
        ),
      );
      saved = true;
      preview = null;
      _bytes = null;
      fileName = null;
      reports = await _repository.listReports();
      await onImported?.call();
      notice =
          'Relatório importado. O arquivo original e os dados foram salvos nesta pasta.';
    } on ReportImportException catch (failure) {
      error = failure.message;
    } catch (_) {
      error = saved
          ? 'Relatório salvo, mas não foi possível atualizar a tela. Reabra o aplicativo para carregar os dados.'
          : 'Não foi possível salvar o relatório. Verifique o acesso à pasta de dados e tente novamente.';
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
    super.dispose();
  }
}
