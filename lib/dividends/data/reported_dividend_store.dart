import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import '../domain/dividend_payment.dart';
import '../domain/reported_dividend.dart';

/// Uses the caller's transaction so files and cash credits commit together.
abstract final class ReportedDividendStore {
  static void initialize(Database db) {
    db.execute(
      '''CREATE TABLE IF NOT EXISTS reported_dividends (
      id TEXT PRIMARY KEY, symbol TEXT NOT NULL, broker TEXT NOT NULL,
      paid_at TEXT NOT NULL, kind TEXT NOT NULL,
      amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
      quantity INTEGER CHECK(quantity > 0), per_share_micros INTEGER CHECK(per_share_micros > 0))''',
    );
    db.execute(
      '''CREATE TABLE IF NOT EXISTS report_dividend_lines (
      report_id TEXT NOT NULL REFERENCES imported_reports(id),
      dividend_id TEXT NOT NULL REFERENCES reported_dividends(id),
      is_new INTEGER NOT NULL CHECK(is_new IN (0, 1)), PRIMARY KEY(report_id, dividend_id))''',
    );
    db.execute('''CREATE TABLE IF NOT EXISTS report_dividend_imports (
      report_id TEXT PRIMARY KEY REFERENCES imported_reports(id))''');
  }

  static bool exists(Database db) => db
      .select(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='reported_dividends'",
      )
      .isNotEmpty;
  static void save(
    Database db,
    String reportId,
    List<ReportedDividend> dividends,
  ) {
    final occurrences = <String, int>{};
    for (final p in dividends) {
      final canonical = jsonEncode([
        p.symbol,
        p.broker,
        p.paymentDate.toIso8601String().substring(0, 10),
        p.kind.name,
        p.amountCents,
        p.quantity,
        p.perShareMicros,
      ]);
      final occurrence = occurrences.update(
        canonical,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
      final id = sha256
          .convert(utf8.encode('$canonical#$occurrence'))
          .toString();
      final isNew = db.select('SELECT 1 FROM reported_dividends WHERE id = ?', [
        id,
      ]).isEmpty;
      if (isNew) {
        db.execute(
          'INSERT INTO reported_dividends VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            id,
            p.symbol,
            p.broker,
            p.paymentDate.toIso8601String().substring(0, 10),
            p.kind.name,
            p.amountCents,
            p.quantity,
            p.perShareMicros,
          ],
        );
      }
      db.execute('INSERT INTO report_dividend_lines VALUES (?, ?, ?)', [
        reportId,
        id,
        isNew ? 1 : 0,
      ]);
    }
    db.execute('INSERT INTO report_dividend_imports VALUES (?)', [reportId]);
  }

  static List<DividendPayment> load(Database db) {
    if (!exists(db)) return [];
    return db
        .select('SELECT * FROM reported_dividends ORDER BY paid_at DESC, id')
        .map(
          (r) => DividendPayment(
            id: 'reported-${r['id']}',
            symbol: r['symbol'] as String,
            amountCents: r['amount_cents'] as int,
            paymentDate: DateTime.parse(r['paid_at'] as String),
            received: true,
            kind: DividendKind.values.byName(r['kind'] as String),
            perShareMicros: r['per_share_micros'] as int?,
            eligibleQuantity: r['quantity'] as int?,
          ),
        )
        .toList();
  }

  static Map<String, int> totals(Database db, DateTime asOf) {
    if (!exists(db)) return {};
    return {
      for (final r in db.select(
        'SELECT symbol, SUM(amount_cents) total FROM reported_dividends WHERE paid_at <= ? GROUP BY symbol',
        [asOf.toIso8601String().substring(0, 10)],
      ))
        r['symbol'] as String: r['total'] as int,
    };
  }
}
