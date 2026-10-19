String normalizeB3Text(Object? value) {
  var text = (value ?? '').toString().trim().toLowerCase();
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'ê': 'e',
    'è': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  for (final entry in accents.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text.replaceAll(RegExp(r'\s+'), ' ');
}

int parseB3Scaled(Object? value, int scale) {
  if (value is num) {
    if (!value.isFinite || value <= 0 || value > 1e10) {
      throw const FormatException('Invalid number');
    }
    final result = (value * scale).round();
    if (result <= 0) {
      throw const FormatException('Number below supported precision');
    }
    return result;
  }
  var text = value
      .toString()
      .replaceAll('R\$', '')
      .replaceAll(RegExp(r'\s'), '');
  if (text.contains(',')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^[1-9]\d{0,2}(\.\d{3})+$').hasMatch(text)) {
    text = text.replaceAll('.', '');
  }
  if (!RegExp(r'^\d+(\.\d{1,8})?$').hasMatch(text)) {
    throw const FormatException('Invalid number');
  }
  final number = double.parse(text);
  if (!number.isFinite || number <= 0 || number > 1e10) {
    throw const FormatException('Invalid number');
  }
  final result = (number * scale).round();
  if (result <= 0) {
    throw const FormatException('Number below supported precision');
  }
  return result;
}

DateTime parseB3Date(Object? value) {
  if (value is DateTime) return DateTime(value.year, value.month, value.day);
  if (value is num) {
    if (value < 1 || value > 100000) {
      throw const FormatException('Invalid date');
    }
    return DateTime(1899, 12, 30).add(Duration(days: value.floor()));
  }
  final text = value.toString().trim();
  final brazil = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:T.*)?$').firstMatch(text);
  final year = int.tryParse(brazil?.group(3) ?? iso?.group(1) ?? '');
  final month = int.tryParse(brazil?.group(2) ?? iso?.group(2) ?? '');
  final day = int.tryParse(brazil?.group(1) ?? iso?.group(3) ?? '');
  if (year == null ||
      month == null ||
      day == null ||
      year < 1970 ||
      year > 2200) {
    throw const FormatException('Invalid date');
  }
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw const FormatException('Invalid date');
  }
  return date;
}
