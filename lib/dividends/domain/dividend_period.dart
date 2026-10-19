enum DividendPeriod {
  inception('Desde o início', null),
  year('Último ano', 12),
  sixMonths('Últimos 6 meses', 6),
  threeMonths('Últimos 3 meses', 3),
  month('Último mês', 1),
  twoYears('Últimos 2 anos', 24),
  fiveYears('Últimos 5 anos', 60);

  const DividendPeriod(this.label, this.months);
  final String label;
  final int? months;

  DateTime? start(DateTime now) {
    final count = months;
    if (count == null) return null;
    final first = DateTime(now.year, now.month - count);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(
      first.year,
      first.month,
      now.day > lastDay ? lastDay : now.day,
    );
  }

  bool contains(DateTime date, DateTime now, {bool includeFuture = false}) {
    final day = DateTime(date.year, date.month, date.day);
    final from = start(now);
    if (from != null && day.isBefore(from)) return false;
    if (this == inception && includeFuture) return true;
    return !day.isAfter(DateTime(now.year, now.month, now.day));
  }
}
