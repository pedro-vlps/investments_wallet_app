import '../../dividends/domain/dividend_payment.dart';
import '../../dividends/domain/reported_dividend.dart';
import '../domain/report_trade.dart';
import 'b3_listed_asset.dart';
import 'b3_value_parser.dart';

DividendKind? b3DividendKind(String movement) => switch (movement) {
  'dividendo' || 'dividendos' => DividendKind.dividend,
  'juros sobre capital proprio' || 'jcp' => DividendKind.interestOnEquity,
  'rendimento' || 'rendimentos' => DividendKind.fundIncome,
  _ => null,
};

ReportedDividend? parseB3Dividend({
  required Object? Function(String) cell,
  required DividendKind kind,
  required String location,
}) {
  final product = (cell('produto') ?? '').toString().trim();
  final symbol = normalizeB3ListedSymbol(
    product.split(RegExp(r'\s+-\s+')).first,
  );
  if (!isSupportedB3ListedSymbol(symbol)) return null;
  try {
    if (![
      'credito',
      'entrada',
    ].contains(normalizeB3Text(cell('entrada/saida')))) {
      throw const FormatException('Only cash credits are supported');
    }
    final broker = (cell('instituicao') ?? '')
        .toString()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toUpperCase();
    if (broker.isEmpty) throw const FormatException('Missing broker');
    int? optionalNumber(String key, int scale) {
      final value = cell(key);
      if (value == null || ['', '-', '—'].contains(value.toString().trim())) {
        return null;
      }
      return parseB3Scaled(value, scale);
    }

    final quantity = optionalNumber('quantidade', 1000000);
    if (quantity != null && quantity % 1000000 != 0) {
      throw const FormatException('Invalid listed quantity');
    }
    final date = parseB3Date(cell('data'));
    final now = DateTime.now();
    if (date.isAfter(DateTime(now.year, now.month, now.day))) {
      throw const FormatException(
        'A movement credit cannot confirm a future payment',
      );
    }
    return ReportedDividend(
      symbol: symbol,
      broker: broker,
      paymentDate: date,
      kind: kind,
      amountCents: parseB3Scaled(cell('valor da operacao'), 100),
      quantity: quantity == null ? null : quantity ~/ 1000000,
      perShareMicros: optionalNumber('preco unitario', 1000000),
      location: location,
    );
  } on FormatException {
    throw ReportImportException(
      '$location: provento com direção, data, instituição ou valores inválidos. Nenhuma linha deste arquivo foi gravada.',
    );
  }
}
