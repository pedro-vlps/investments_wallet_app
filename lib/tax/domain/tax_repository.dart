import 'tax_month.dart';

class TaxYearData {
  const TaxYearData(this.opening, this.months);
  final TaxOpening? opening;
  final List<TaxMonth> months;
}

abstract interface class TaxRepository {
  Future<TaxYearData> loadYear(int year);
  Future<void> saveMonth(TaxMonth month);
  Future<void> deleteMonth(int year, int month);
  Future<void> saveOpening(TaxOpening opening);
  Future<String?> loadCheckState();
  Future<void> saveCheckState(String state);
}
