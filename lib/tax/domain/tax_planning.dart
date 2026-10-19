import 'tax_assessment.dart';
import 'tax_month.dart';

enum TaxPlanningGroup { stock, common, dayTrade, fund }

/// A proposed additional net result. It does not create trades or tax records.
TaxAssessment simulateTaxMonth({
  required int year,
  required int month,
  required TaxOpening? opening,
  required List<TaxMonth> recorded,
  required TaxPlanningGroup group,
  required int additionalResult,
  required int additionalStockSales,
}) {
  final existing =
      recorded.where((m) => m.month == month).firstOrNull ??
      TaxMonth(year: year, month: month);
  final scenario = TaxMonth(
    year: year,
    month: month,
    stockSales:
        existing.stockSales +
        (group == TaxPlanningGroup.stock ? additionalStockSales : 0),
    stockResult:
        existing.stockResult +
        (group == TaxPlanningGroup.stock ? additionalResult : 0),
    otherCommonResult:
        existing.otherCommonResult +
        (group == TaxPlanningGroup.common ? additionalResult : 0),
    dayTradeResult:
        existing.dayTradeResult +
        (group == TaxPlanningGroup.dayTrade ? additionalResult : 0),
    fundResult:
        existing.fundResult +
        (group == TaxPlanningGroup.fund ? additionalResult : 0),
    commonWithheld: existing.commonWithheld,
    dayTradeWithheld: existing.dayTradeWithheld,
    fundWithheld: existing.fundWithheld,
    paid: existing.paid,
  );
  if (additionalStockSales < 0 ||
      (group == TaxPlanningGroup.stock &&
          additionalResult > additionalStockSales)) {
    throw const FormatException(
      'Resultado de ações não pode superar as vendas propostas.',
    );
  }
  return assessTaxYear(opening, [
    ...recorded.where((m) => m.month < month),
    scenario,
  ]).last;
}
