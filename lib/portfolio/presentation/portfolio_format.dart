import 'package:intl/intl.dart';

export '../../financial_display/number_format.dart';

final _timestamp = DateFormat('dd/MM/yyyy HH:mm');

String formatQuoteTime(DateTime time) =>
    '${_timestamp.format(time.toLocal())} (local)';
