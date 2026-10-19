import '../../reports/domain/report_trade.dart';
import 'tax_assessment.dart';
import 'tax_month.dart';
import 'tax_rule_status.dart';
import 'tax_rules.dart';

/// Auxiliary data, never a PGD import file, completed return or transmission.
Map<String, Object?> buildTaxAnnualReport({
  required int year,
  required DateTime now,
  required TaxRuleStatus status,
  required TaxOpening? opening,
  required List<TaxMonth> months,
  required List<ReportTrade> trades,
}) {
  if (!status.annualExportAvailable(now) || year >= now.year) {
    throw const FormatException(
      'Geração anual disponível somente na janela de preparação, para anos encerrados.',
    );
  }
  final assessments = assessTaxYear(opening, months);
  if ((opening != null && opening.year != year) ||
      months.any((m) => m.year != year)) {
    throw const FormatException(
      'Os registros não correspondem ao ano selecionado.',
    );
  }
  final reviewed =
      assessments.length == 12 && assessments.every((a) => a.complete);
  return {
    'documentType': 'auxiliary_investment_tax_report_not_a_tax_return',
    'calendarYear': year,
    'filingYear': year + 1,
    'generatedAt': now.toIso8601String(),
    'rulesRevision': TaxRules.revision,
    'reviewedAt': TaxRules.reviewedAt.toIso8601String(),
    'sourcesCheckedAt': status.checkedAt?.toIso8601String(),
    'changedSources': status.changedSources,
    'twelveMonthsReviewed': reviewed,
    'limitations': [
      'Not a complete DIRPF, PGD import file, DARF or transmission receipt.',
      'Monthly results are manually reconciled across all brokers for one resident CPF.',
      'Imported trades omit fees, IRRF, corporate actions, initial tax costs and income statements.',
      'Review acquisition costs on December 31 in both years, taxpayer data, CNPJ, income and other assets in the official declaration.',
      'Treasury and fixed-income ETFs: source withholding and statements, not DARF 6015.',
      'Dividend, JCP, FII distribution and BDR income must follow issuer statements and their own tax regimes.',
      '2026: JCP withholding 17.5%; dividend withholding above BRL 50,000 per payer/month and annual high-income taxation require individual review, including transitional exceptions.',
      'Late payments require Sicalc penalties and interest; paid principal is not an automatically confirmed tax payment.',
    ],
    'opening': opening == null
        ? null
        : {
            'commonLossCents': opening.commonLoss,
            'dayTradeLossCents': opening.dayTradeLoss,
            'fundLossCents': opening.fundLoss,
            'smallDarfCents': opening.smallDarf,
          },
    'months': [
      for (final a in assessments)
        {
          'month': a.input.month,
          'stockSalesCents': a.input.stockSales,
          'stockResultCents': a.input.stockResult,
          'otherCommonResultCents': a.input.otherCommonResult,
          'dayTradeResultCents': a.input.dayTradeResult,
          'fundResultCents': a.input.fundResult,
          'commonWithheldCents': a.input.commonWithheld,
          'dayTradeWithheldCents': a.input.dayTradeWithheld,
          'fundWithheldCents': a.input.fundWithheld,
          'exemptGainCents': a.exemptGain,
          'commonTaxAfterWithholdingCents': a.commonTax,
          'dayTradeTaxAfterWithholdingCents': a.dayTradeTax,
          'fundTaxAfterWithholdingCents': a.fundTax,
          'darfPrincipalCents': a.darf,
          'paidPrincipalCents': a.input.paid,
          'unpaidPrincipalCents': a.unpaidPrincipal,
          'smallDarfCents': a.smallDarf,
          'remainingCommonLossCents': a.commonLoss,
          'remainingDayTradeLossCents': a.dayTradeLoss,
          'remainingFundLossCents': a.fundLoss,
          'remainingCommonIrrfCents': a.commonCredit,
          'remainingDayTradeIrrfCents': a.dayTradeCredit,
          'remainingFundIrrfCents': a.fundCredit,
          'complete': a.complete,
          'notes': a.input.notes,
        },
    ],
    'importedTradesForReconciliation': [
      for (final t in trades.where((t) => t.date.year == year))
        {
          'date': t.date.toIso8601String(),
          'symbol': t.symbol,
          'broker': t.broker,
          'side': t.side.name,
          'category': t.category?.name,
          'quantityMicros': t.quantityMicros,
          'grossTotalCents': t.totalCents,
        },
    ],
  };
}
