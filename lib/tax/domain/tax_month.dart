/// Values are signed net results, after documented deductible trading costs.
/// All broker accounts belonging to the same CPF must be consolidated first.
class TaxMonth {
  const TaxMonth({
    required this.year,
    required this.month,
    this.stockSales = 0,
    this.stockResult = 0,
    this.otherCommonResult = 0,
    this.dayTradeResult = 0,
    this.fundResult = 0,
    this.commonWithheld = 0,
    this.dayTradeWithheld = 0,
    this.fundWithheld = 0,
    this.paid = 0,
    this.notes = '',
  });
  final int year;
  final int month;
  final int stockSales;
  final int stockResult;
  final int otherCommonResult;
  final int dayTradeResult;
  final int fundResult;
  final int commonWithheld;
  final int dayTradeWithheld;
  final int fundWithheld;
  final int paid;
  final String notes;

  void validate() {
    if (year < 2025 ||
        year > 2100 ||
        month < 1 ||
        month > 12 ||
        [
          stockSales,
          commonWithheld,
          dayTradeWithheld,
          fundWithheld,
          paid,
        ].any((v) => v < 0) ||
        stockResult > stockSales ||
        notes.length > 2000 ||
        values.any((v) => v.abs() > 10000000000000)) {
      throw const FormatException('Dados mensais inválidos.');
    }
  }

  List<int> get values => [
    stockSales,
    stockResult,
    otherCommonResult,
    dayTradeResult,
    fundResult,
    commonWithheld,
    dayTradeWithheld,
    fundWithheld,
    paid,
  ];
}

/// Prior-year losses survive the year boundary. IRRF does not automatically
/// cross years; it must be handled using the annual declaration/refund process.
class TaxOpening {
  const TaxOpening({
    required this.year,
    this.commonLoss = 0,
    this.dayTradeLoss = 0,
    this.fundLoss = 0,
    this.smallDarf = 0,
  });
  final int year;
  final int commonLoss;
  final int dayTradeLoss;
  final int fundLoss;
  final int smallDarf;

  void validate() {
    if (year < 2025 ||
        year > 2100 ||
        [
          commonLoss,
          dayTradeLoss,
          fundLoss,
          smallDarf,
        ].any((v) => v < 0 || v > 10000000000000) ||
        smallDarf >= 1000) {
      throw const FormatException('Saldos iniciais inválidos.');
    }
  }
}
