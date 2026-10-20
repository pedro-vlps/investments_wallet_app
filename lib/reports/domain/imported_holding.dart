import '../../portfolio/domain/asset_category.dart';
import 'report_trade.dart';

class ImportedHolding {
  ImportedHolding(
    this.symbol,
    this.name,
    this.category,
    this.broker, {
    this.dateBasis = ReportDateBasis.trade,
  });
  final String symbol;
  final String name;
  final AssetCategory category;
  final String broker;
  final ReportDateBasis dateBasis;
  int quantityMicros = 0;
  int costCents = 0;
  int lastPriceMicros = 0;
  DateTime date = DateTime(1970);
}

/// Rebuild from the complete history, so importing an older period is safe.
List<ImportedHolding> projectImportedHoldings(Iterable<ReportTrade> trades) {
  final ordered = trades.toList()
    ..sort((a, b) {
      final dateOrder = a.date.compareTo(b.date);
      if (dateOrder != 0) return dateOrder;
      // Daily B3 extracts have no execution time; purchases cover same-day sales.
      return a.side.index.compareTo(b.side.index);
    });
  final holdings = <(String, String), ImportedHolding>{};
  final categories = <String, AssetCategory>{};
  for (final trade in ordered) {
    if (trade.category == null ||
        trade.quantityMicros <= 0 ||
        trade.priceMicros <= 0 ||
        trade.totalCents <= 0 ||
        trade.broker.isEmpty) {
      throw const ReportImportException(
        'Operação inválida ou sem classificação.',
      );
    }
    if (categories.containsKey(trade.symbol) &&
        categories[trade.symbol] != trade.category) {
      throw ReportImportException(
        'Classificações conflitantes para ${trade.symbol}.',
      );
    }
    categories[trade.symbol] = trade.category!;
    final holding = holdings.putIfAbsent(
      (trade.symbol, trade.broker),
      () => ImportedHolding(
        trade.symbol,
        trade.name,
        trade.category!,
        trade.broker,
        dateBasis: trade.dateBasis,
      ),
    );
    if (holding.category != trade.category) {
      throw ReportImportException(
        'Classificações conflitantes para ${trade.symbol}.',
      );
    }
    if (holding.dateBasis != trade.dateBasis) {
      throw ReportImportException(
        'O histórico de ${trade.symbol} nesta instituição já usa outra base de data. '
        'Use somente negociações ou somente liquidações para o mesmo ativo e instituição, '
        'para não contar a mesma operação duas vezes. A data de liquidação não é a data do negócio.',
      );
    }
    if (trade.side == TradeSide.buy) {
      holding.quantityMicros += trade.quantityMicros;
      holding.costCents += trade.totalCents;
    } else {
      if (trade.quantityMicros > holding.quantityMicros) {
        throw ReportImportException(
          'Histórico incompleto: venda de ${trade.symbol} '
          'em ${trade.broker} sem saldo suficiente. Importe as compras anteriores primeiro.',
        );
      }
      final removedCost =
          (holding.costCents * trade.quantityMicros / holding.quantityMicros)
              .round();
      holding.quantityMicros -= trade.quantityMicros;
      holding.costCents -= removedCost;
      if (holding.quantityMicros == 0) holding.costCents = 0;
    }
    holding.lastPriceMicros = trade.priceMicros;
    holding.date = trade.date;
  }
  return holdings.values.where((h) => h.quantityMicros > 0).toList();
}
