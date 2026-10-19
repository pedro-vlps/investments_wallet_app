import 'package:flutter/foundation.dart';

import '../../quotes/domain/quote_provider.dart';
import '../domain/portfolio_position.dart';
import '../domain/portfolio_repository.dart';
import '../domain/asset_category.dart';

class PortfolioController extends ChangeNotifier {
  PortfolioController(this._repository, this._quoteProvider);
  final PortfolioRepository _repository;
  final QuoteProvider _quoteProvider;

  List<PortfolioPosition> positions = const [];
  bool loading = true;
  bool syncing = false;
  String? error;
  String? notice;
  bool _disposed = false;

  Future<void> load() async {
    loading = true;
    error = null;
    _emit();
    try {
      positions = await _repository.loadPositions();
    } catch (_) {
      error = 'Não foi possível ler a carteira local. Tente novamente.';
    } finally {
      loading = false;
      _emit();
    }
  }

  Future<void> synchronize() async {
    if (syncing || loading || positions.isEmpty) return;
    syncing = true;
    error = null;
    notice = null;
    _emit();
    try {
      final eligible = positions
          .where((p) => p.category != AssetCategory.treasury)
          .toList();
      if (eligible.isEmpty) {
        notice =
            'Tesouro Direto mantém o preço da última operação. A atualização automática de títulos ainda não está disponível.';
        return;
      }
      final quotes = await _quoteProvider.fetchQuotes(
        eligible.map((position) => position.symbol).toList(),
      );
      if (quotes.length != eligible.length ||
          !quotes
              .map((q) => q.symbol)
              .toSet()
              .containsAll(eligible.map((p) => p.symbol))) {
        throw const QuoteException('O provedor retornou dados incompletos.');
      }
      await _repository.saveQuotes(quotes);
      positions = await _repository.loadPositions();
      notice =
          'Consulta concluída. Exibindo as últimas cotações disponíveis.'
          '${eligible.length < positions.length ? ' Tesouro Direto mantém o preço da última operação.' : ''}';
    } on QuoteException catch (failure) {
      error = '${failure.message} Os dados salvos foram mantidos.';
    } catch (_) {
      error =
          'Não foi possível concluir a atualização. '
          'As últimas posições carregadas continuam disponíveis. Tente novamente.';
    } finally {
      syncing = false;
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
