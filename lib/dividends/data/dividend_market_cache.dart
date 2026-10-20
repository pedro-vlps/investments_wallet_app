import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import '../domain/dividend_market_data.dart';

abstract final class DividendMarketCache {
  static void initialize(Database db) =>
      db.execute('''CREATE TABLE IF NOT EXISTS dividend_market_cache (
    symbol TEXT PRIMARY KEY, payload TEXT NOT NULL)''');
  static List<DividendMarketData> load(Database db) {
    if (db
        .select(
          "SELECT 1 FROM sqlite_master WHERE type='table' AND name='dividend_market_cache'",
        )
        .isEmpty) {
      return [];
    }
    return db
        .select('SELECT payload FROM dividend_market_cache ORDER BY symbol')
        .map(
          (r) => DividendMarketData.fromJson(
            jsonDecode(r['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static void save(Database db, List<DividendMarketData> updates) {
    initialize(db);
    final previous = {for (final item in load(db)) item.symbol: item};
    for (final update in updates) {
      final old = previous[update.symbol];
      final merged = DividendMarketData(
        symbol: update.symbol,
        checkedAt: update.checkedAt,
        announcements: update.announcementsUpdated
            ? update.announcements
            : old?.announcements ?? [],
        closes: update.pricesUpdated ? update.closes : old?.closes ?? {},
        hasCorporateActions: update.announcementsUpdated
            ? update.hasCorporateActions
            : old?.hasCorporateActions ?? false,
        announcementsUpdated: update.announcementsUpdated,
        pricesUpdated: update.pricesUpdated,
        warnings: update.warnings,
      );
      db.execute(
        'INSERT INTO dividend_market_cache VALUES (?, ?) ON CONFLICT(symbol) DO UPDATE SET payload = excluded.payload',
        [update.symbol, jsonEncode(merged.toJson())],
      );
    }
  }
}
