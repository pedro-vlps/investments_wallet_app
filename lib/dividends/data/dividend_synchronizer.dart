import 'dart:isolate';
import 'package:sqlite3/sqlite3.dart';
import '../../portfolio/domain/asset_category.dart';
import '../../reports/domain/report_repository.dart';
import '../domain/dividend_market_data.dart';
import 'brapi_dividend_provider.dart';
import 'dividend_market_cache.dart';

class DividendSynchronizer {
  const DividendSynchronizer(this.databasePath, this.reports, this.provider);
  final String databasePath;
  final ReportRepository reports;
  final BrapiDividendProvider provider;
  Future<void> synchronize(DateTime asOf) async {
    final trades = await reports.listTrades();
    final symbols = trades.map((t) => t.symbol).toSet();
    final updates = <DividendMarketData>[];
    for (final symbol in symbols) {
      final history = trades.where((t) => t.symbol == symbol).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (history.first.category == AssetCategory.treasury) continue;
      if (history.first.category == null) continue;
      updates.add(
        await provider.fetch(
          symbol,
          history.first.category!,
          history.first.date,
          asOf,
        ),
      );
    }
    await _saveUpdates(databasePath, updates);
  }
}

Future<void> _saveUpdates(
  String databasePath,
  List<DividendMarketData> updates,
) => Isolate.run(() {
  final db = sqlite3.open(databasePath);
  try {
    db.execute('BEGIN IMMEDIATE');
    try {
      DividendMarketCache.save(db, updates);
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  } finally {
    db.close();
  }
});
