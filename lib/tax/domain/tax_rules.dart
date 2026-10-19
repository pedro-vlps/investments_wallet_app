/// Reviewed rules for Brazilian resident individuals and domestic B3 operations.
/// A source check is not a legal review or permission to change these rules.
abstract final class TaxRules {
  static const revision = 'BR-PF-2026-10-19';
  static final reviewedAt = DateTime(2026, 10, 19);
  static const stockExemptionCents = 2000000;
  static const minimumDarfCents = 1000;
  static const commonRateBasisPoints = 1500;
  static const dayTradeRateBasisPoints = 2000;
  static const fundRateBasisPoints = 2000;

  static DateTime nextReview(DateTime checkedAt) {
    final month = DateTime(checkedAt.year, checkedAt.month + 6);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(
      month.year,
      month.month,
      checkedAt.day > lastDay ? lastDay : checkedAt.day,
    );
  }

  static int taxOn(int cents, int basisPoints) =>
      (cents * basisPoints) ~/ 10000;
}
