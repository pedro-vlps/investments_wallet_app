import 'dividend_payment.dart';

/// A cash credit reported by the custodian, without inferred entitlement dates.
class ReportedDividend {
  ReportedDividend({
    required this.symbol,
    required this.broker,
    required this.paymentDate,
    required this.kind,
    required this.amountCents,
    required this.location,
    this.quantity,
    this.perShareMicros,
  }) {
    if (symbol.isEmpty ||
        broker.isEmpty ||
        amountCents <= 0 ||
        (quantity != null && quantity! <= 0) ||
        (perShareMicros != null && perShareMicros! <= 0)) {
      throw ArgumentError('Invalid reported dividend');
    }
  }
  final String symbol;
  final String broker;
  final DateTime paymentDate;
  final DividendKind kind;
  // Preserve the actual reported credit; do not recalculate taxes or gross it up.
  final int amountCents;
  final int? quantity;
  final int? perShareMicros;
  final String location;
}
