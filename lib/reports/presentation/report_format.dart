import 'package:intl/intl.dart';
import '../../portfolio/domain/asset_category.dart';

String formatReportQuantity(int micros) =>
    NumberFormat('#,##0.######', 'pt_BR').format(micros / 1000000);

String assetCategoryLabel(AssetCategory category) => switch (category) {
  AssetCategory.stock => 'Ação / unit',
  AssetCategory.realEstateFund => 'Fundo imobiliário',
  AssetCategory.etf => 'ETF',
  AssetCategory.treasury => 'Tesouro Direto',
  AssetCategory.bdr => 'BDR',
};
