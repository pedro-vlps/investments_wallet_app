import '../../portfolio/domain/asset_category.dart';

// The B3 trading manual reserves suffixes 31 through 40 for BDRs.
// Alphanumeric roots include securities such as A1MD34 and K1LA34.
bool isB3BdrSymbol(String symbol) =>
    RegExp(r'^[A-Z][A-Z0-9]{3}(3[1-9]|40)$').hasMatch(symbol);

bool isSupportedB3ListedSymbol(String symbol) =>
    isB3BdrSymbol(symbol) ||
    RegExp(r'^[A-Z]{4}(3|4|5|6|7|8|11)$').hasMatch(symbol);

String normalizeB3ListedSymbol(String value) {
  final symbol = value.trim().toUpperCase();
  if (symbol.endsWith('F')) {
    final standard = symbol.substring(0, symbol.length - 1);
    if (isSupportedB3ListedSymbol(standard)) return standard;
  }
  return symbol;
}

AssetCategory? classifyB3ListedAsset(String symbol, String categoryText) {
  // ETF-backed receipts remain BDRs even when the sheet mentions ETFs.
  if (isB3BdrSymbol(symbol)) return AssetCategory.bdr;
  if (RegExp(r'\betf\b').hasMatch(categoryText)) return AssetCategory.etf;
  if (categoryText.contains('imobili') ||
      RegExp(r'\bfii\b').hasMatch(categoryText)) {
    return AssetCategory.realEstateFund;
  }
  return symbol.endsWith('11') ? null : AssetCategory.stock;
}
