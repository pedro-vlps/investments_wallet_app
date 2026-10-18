import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);
final _percentage = NumberFormat.decimalPatternDigits(
  locale: 'pt_BR',
  decimalDigits: 2,
);
final _timestamp = DateFormat('dd/MM/yyyy HH:mm');

String formatMoney(int cents) => _currency.format(cents / 100);
String formatPercent(double value) =>
    '${value >= 0 ? '+' : ''}${_percentage.format(value)}%';
String formatQuoteTime(DateTime time) =>
    '${_timestamp.format(time.toLocal())} (local)';
