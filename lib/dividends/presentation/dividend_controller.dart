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
