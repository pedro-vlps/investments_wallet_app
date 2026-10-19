import 'dart:math' as math;

import 'tax_month.dart';
import 'tax_rules.dart';

class TaxAssessment {
  const TaxAssessment({
    required this.input,
    required this.exemptGain,
    required this.commonTax,
    required this.dayTradeTax,
    required this.fundTax,
    required this.commonLoss,
    required this.dayTradeLoss,
    required this.fundLoss,
    required this.commonCredit,
    required this.dayTradeCredit,
    required this.fundCredit,
    required this.darf,
    required this.smallDarf,
    required this.complete,
  });
  final TaxMonth input;
  final int exemptGain;
  final int commonTax;
  final int dayTradeTax;
  final int fundTax;
  final int commonLoss;
  final int dayTradeLoss;
  final int fundLoss;
  final int commonCredit;
  final int dayTradeCredit;
  final int fundCredit;

  /// Principal only. Late-payment interest and penalties belong to Sicalc.
  final int darf;
  final int smallDarf;
  final bool complete;
  int get unpaidPrincipal => math.max(0, darf - input.paid);
}

List<TaxAssessment> assessTaxYear(TaxOpening? opening, List<TaxMonth> months) {
  if (months.isEmpty) return const [];
  opening?.validate();
  final ordered = [...months]..sort((a, b) => a.month.compareTo(b.month));
  final year = ordered.first.year;
  if ((opening != null && opening.year != year) ||
      ordered.any((m) => m.year != year) ||
      ordered.map((m) => m.month).toSet().length != ordered.length) {
    throw const FormatException(
      'Apuração exige um único ano, sem meses repetidos.',
    );
  }
  var commonLoss = opening?.commonLoss ?? 0;
  var dayLoss = opening?.dayTradeLoss ?? 0;
  var fundLoss = opening?.fundLoss ?? 0;
  var smallDarf = opening?.smallDarf ?? 0;
  var commonCredit = 0;
  var dayCredit = 0;
  var fundCredit = 0;
  var previousMonth = 0;
  var complete = opening != null;
  final result = <TaxAssessment>[];
  for (final month in ordered) {
    month.validate();
    complete = complete && month.month == previousMonth + 1;
    previousMonth = month.month;
    final exempt =
        month.stockSales <= TaxRules.stockExemptionCents &&
            month.stockResult > 0
        ? month.stockResult
        : 0;
    // Exempt gains do not consume tax losses. Negative stock results remain
    // eligible for compensation even in months below the exemption threshold.
    final common = month.stockResult - exempt + month.otherCommonResult;
    final commonBase = math.max(0, common - commonLoss);
    final dayBase = math.max(0, month.dayTradeResult - dayLoss);
    final fundBase = math.max(0, month.fundResult - fundLoss);
    commonLoss = math.max(0, commonLoss - common);
    dayLoss = math.max(0, dayLoss - month.dayTradeResult);
    fundLoss = math.max(0, fundLoss - month.fundResult);
    commonCredit += month.commonWithheld;
    dayCredit += month.dayTradeWithheld;
    fundCredit += month.fundWithheld;
    final commonGross = TaxRules.taxOn(
      commonBase,
      TaxRules.commonRateBasisPoints,
    );
    final dayGross = TaxRules.taxOn(dayBase, TaxRules.dayTradeRateBasisPoints);
    final fundGross = TaxRules.taxOn(fundBase, TaxRules.fundRateBasisPoints);
    final commonTax = math.max(0, commonGross - commonCredit);
    final dayTax = math.max(0, dayGross - dayCredit);
    final fundTax = math.max(0, fundGross - fundCredit);
    commonCredit = math.max(0, commonCredit - commonGross);
    dayCredit = math.max(0, dayCredit - dayGross);
    fundCredit = math.max(0, fundCredit - fundGross);
    final accumulated = commonTax + dayTax + fundTax + smallDarf;
    final darf = accumulated >= TaxRules.minimumDarfCents ? accumulated : 0;
    smallDarf = darf == 0 ? accumulated : 0;
    result.add(
      TaxAssessment(
        input: month,
        exemptGain: exempt,
        commonTax: commonTax,
        dayTradeTax: dayTax,
        fundTax: fundTax,
        commonLoss: commonLoss,
        dayTradeLoss: dayLoss,
        fundLoss: fundLoss,
        commonCredit: commonCredit,
        dayTradeCredit: dayCredit,
        fundCredit: fundCredit,
        darf: darf,
        smallDarf: smallDarf,
        complete: complete,
      ),
    );
  }
  return result;
}
