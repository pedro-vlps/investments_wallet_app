import 'package:intl/intl.dart';

export '../../financial_display/number_format.dart';

final _perShare = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 6,
);
String formatPerShare(int? micros) =>
    micros == null ? 'Não informado' : _perShare.format(micros / 1000000);
String formatDividendDate(DateTime? date) =>
    date == null ? 'Não informado' : DateFormat('dd/MM/yyyy').format(date);
String formatDividendMonth(DateTime date) => DateFormat('MM/yy').format(date);
