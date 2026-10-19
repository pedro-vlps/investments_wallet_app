enum DividendKind { dividend, interestOnEquity }

class DividendPayment {
  DividendPayment({
    required this.id,
    required this.symbol,
    required this.amountCents,
    required this.paymentDate,
    required this.received,
    required this.kind,
    this.perShareMicros,
    this.eligibleQuantity,
    this.cumDate,
    this.exDate,
  }) {
    if (id.isEmpty ||
        symbol.isEmpty ||
        amountCents <= 0 ||
        (perShareMicros != null && perShareMicros! <= 0) ||
        (eligibleQuantity != null && eligibleQuantity! <= 0) ||
        (cumDate != null && exDate != null && !exDate!.isAfter(cumDate!))) {
      throw ArgumentError('Invalid dividend payment');
    }
  }
  final String id;
  final String symbol;
  final int amountCents;
  final DateTime paymentDate;
  final bool received;
  final DividendKind kind;
  // One real is one million micro-reais; sub-cent per-share values are retained.
  final int? perShareMicros;
  final int? eligibleQuantity;
  final DateTime? cumDate;
  final DateTime? exDate;
}
