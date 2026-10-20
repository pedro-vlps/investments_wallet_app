import 'package:flutter/foundation.dart';

import '../domain/dividend_repository.dart';

class DividendController extends ChangeNotifier {
  DividendController(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DividendRepository _repository;
  final DateTime Function() _now;
  DateTime get asOf => _now();
  DividendData data = const DividendData(payments: [], valuations: []);
  bool loading = true;
  String? error;
  bool _disposed = false;
  Future<void> Function(DateTime)? synchronizeMarket;
  bool syncing = false;
  String? syncMessage;
  DateTime? _lastAttempt;

  Future<void> refreshIfStale() async {
    final checked = _lastAttempt ?? data.checkedAt;
    if (checked == null ||
        asOf.difference(checked) >= const Duration(days: 1)) {
      await synchronize();
    }
  }

  Future<void> synchronize() async {
    if (syncing || _disposed || synchronizeMarket == null) return;
    syncing = true;
    _lastAttempt = asOf;
    syncMessage = null;
    notifyListeners();
    try {
      await synchronizeMarket!(asOf);
      if (_disposed) return;
      data = await _repository.loadData();
      syncMessage = data.warnings.isEmpty
          ? 'Proventos e histórico atualizados e salvos neste dispositivo.'
          : 'Consulta concluída com pendências. Os dados disponíveis foram mantidos.';
    } catch (_) {
      syncMessage =
          'Não foi possível atualizar proventos e histórico. Os dados locais foram mantidos. Confira a conexão e a configuração de cotações.';
    } finally {
      syncing = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> load() async {
    loading = true;
    error = null;
    if (!_disposed) notifyListeners();
    try {
      data = await _repository.loadData();
    } catch (_) {
      error = 'Não foi possível ler os dividendos locais. Tente novamente.';
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
