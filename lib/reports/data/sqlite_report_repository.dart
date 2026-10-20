import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import '../../portfolio/domain/asset_category.dart';
import '../domain/imported_holding.dart';
import '../domain/report_document.dart';
import '../domain/report_repository.dart';
import '../domain/report_trade.dart';
import 'report_schema.dart';

class SqliteReportRepository implements ReportRepository {
  const SqliteReportRepository(this.databasePath, this.reportDirectory);
  final String databasePath;
  final String reportDirectory;

  @override
  Future<List<ReportTrade>> listTrades() => Isolate.run(() {
    final database = sqlite3.open(databasePath, mode: OpenMode.readOnly);
    try {
      return hasReports(database) ? _trades(database) : <ReportTrade>[];
    } finally {
      database.close();
    }
  });

  /// Portfolio and dividends use these public infrastructure contracts.
  static bool hasReports(Database database) =>
      database
          .select(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='imported_reports'",
          )
          .isNotEmpty &&
      database.select('SELECT 1 FROM imported_reports LIMIT 1').isNotEmpty;

  static List<ImportedHolding> holdings(Database database) =>
      projectImportedHoldings(_trades(database));

  static List<ReportTrade> _trades(Database database) => database
      .select('SELECT * FROM report_trades ORDER BY occurred_at, id')
      .map(
        (r) => ReportTrade(
          symbol: r['symbol'] as String,
          name: r['name'] as String,
          broker: r['broker'] as String,
          date: DateTime.parse(r['occurred_at'] as String),
          side: TradeSide.values.byName(r['side'] as String),
          quantityMicros: r['quantity_micros'] as int,
          priceMicros: r['price_micros'] as int,
          totalCents: r['total_cents'] as int,
          category: AssetCategory.values.byName(r['category'] as String),
          dateBasis: ReportDateBasis.values.byName(r['date_basis'] as String),
          sourceMovement: r['source_movement'] as String,
          location: 'Banco local',
        ),
      )
      .toList();

  @override
  Future<List<StoredReport>> listReports() => Isolate.run(() {
    final database = sqlite3.open(databasePath);
    try {
      initializeReportSchema(database);
      return database
          .select(
            'SELECT * FROM imported_reports ORDER BY imported_at DESC, id',
          )
          .map((r) {
            final assets = database.select(
              '''SELECT t.symbol, MAX(t.name) name,
          SUM(CASE WHEN l.is_new = 1 AND t.side = 'buy' THEN t.quantity_micros ELSE 0 END) bought,
          SUM(CASE WHEN l.is_new = 1 AND t.side = 'sell' THEN t.quantity_micros ELSE 0 END) sold,
          SUM(l.is_new) new_trades,
          SUM(CASE WHEN t.date_basis = 'settlement' THEN 1 ELSE 0 END) settlements
          FROM report_lines l JOIN report_trades t ON t.id = l.trade_id
          WHERE l.report_id = ? GROUP BY t.symbol ORDER BY t.symbol''',
              [r['id']],
            );
            final issues =
                jsonDecode(r['issues_json'] as String) as List<dynamic>;
            return StoredReport(
              id: r['id'] as String,
              name: r['name'] as String,
              importedAt: DateTime.parse(r['imported_at'] as String),
              relativePath: r['relative_path'] as String,
              duplicateTrades: r['duplicate_trades'] as int,
              assets: assets
                  .map(
                    (a) => ReportAssetSummary(
                      symbol: a['symbol'] as String,
                      name: a['name'] as String,
                      boughtMicros: a['bought'] as int,
                      soldMicros: a['sold'] as int,
                      newTrades: a['new_trades'] as int,
                      settlementTrades: a['settlements'] as int,
                    ),
                  )
                  .toList(),
              issues: issues.map((i) {
                final item = i as Map<String, dynamic>;
                return ReportIssue(
                  item['location'] as String,
                  item['reason'] as String,
                );
              }).toList(),
            );
          })
          .toList();
    } finally {
      database.close();
    }
  });

  @override
  Future<void> importReport({
    required String name,
    required Uint8List bytes,
    required ParsedReport report,
  }) => Isolate.run(() {
    if (report.trades.isEmpty) {
      throw const ReportImportException(
        'Nenhuma compra ou venda elegível neste relatório.',
      );
    }
    final extension = path.extension(name).toLowerCase();
    if (!['.xlsx', '.csv'].contains(extension) ||
        bytes.isEmpty ||
        bytes.length > 10 * 1024 * 1024) {
      throw const ReportImportException(
        'Arquivo inválido. Use XLSX ou CSV de até 10 MB.',
      );
    }
    final id = sha256.convert(bytes).toString();
    final relativePath = 'reports/$id$extension';
    final destination = File(path.join(reportDirectory, '$id$extension'));
    final temporary = File(
      '${destination.path}.${DateTime.now().microsecondsSinceEpoch}.pending',
    );
    final database = sqlite3.open(databasePath);
    var createdFile = false;
    try {
      database.execute('PRAGMA foreign_keys = ON');
      database.execute('PRAGMA busy_timeout = 5000');
      initializeReportSchema(database);
      database.execute('BEGIN IMMEDIATE');
      try {
        if (database.select('SELECT id FROM imported_reports WHERE id = ?', [
          id,
        ]).isNotEmpty) {
          throw const ReportImportException('Este arquivo já foi importado.');
        }
        final occurrences = <String, int>{};
        final candidates = <(String, ReportTrade, bool)>[];
        var duplicates = 0;
        for (final trade in report.trades) {
          final canonical = jsonEncode([
            trade.symbol,
            trade.broker,
            trade.date.toIso8601String().substring(0, 10),
            trade.side.name,
            trade.quantityMicros,
            trade.priceMicros,
            trade.totalCents,
            // Preserve legacy trade hashes; settlement dates are a distinct basis.
            if (trade.dateBasis != ReportDateBasis.trade) trade.dateBasis.name,
          ]);
          final occurrence = occurrences.update(
            canonical,
            (v) => v + 1,
            ifAbsent: () => 1,
          );
          final tradeId = sha256
              .convert(utf8.encode('$canonical#$occurrence'))
              .toString();
          final exists = database.select(
            'SELECT category FROM report_trades WHERE id = ?',
            [tradeId],
          );
          if (exists.isNotEmpty &&
              exists.single['category'] != trade.category?.name) {
            throw ReportImportException(
              'Classificação diferente da já salva para ${trade.symbol}.',
            );
          }
          if (exists.isNotEmpty) duplicates++;
          candidates.add((tradeId, trade, exists.isEmpty));
        }
        // Validate the full rebuilt timeline before writing either the file or rows.
        projectImportedHoldings([
          ..._trades(database),
          ...candidates.where((c) => c.$3).map((c) => c.$2),
        ]);
        Directory(reportDirectory).createSync(recursive: true);
        if (destination.existsSync()) {
          if (sha256.convert(destination.readAsBytesSync()).toString() != id) {
            throw const ReportImportException(
              'O arquivo de destino está inconsistente. Verifique a pasta de backup.',
            );
          }
        } else {
          temporary.writeAsBytesSync(bytes, flush: true);
          temporary.renameSync(destination.path);
          createdFile = true;
        }
        database.execute(
          'INSERT INTO imported_reports VALUES (?, ?, ?, ?, ?, ?)',
          [
            id,
            path.basename(name),
            DateTime.now().toUtc().toIso8601String(),
            relativePath,
            duplicates,
            jsonEncode(
              report.issues
                  .map((i) => {'location': i.location, 'reason': i.reason})
                  .toList(),
            ),
          ],
        );
        for (final (tradeId, trade, isNew) in candidates) {
          if (isNew) {
            database.execute(
              '''INSERT INTO report_trades
                (id, symbol, name, broker, occurred_at, side, quantity_micros,
                 price_micros, total_cents, category, date_basis, source_movement)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
              [
                tradeId,
                trade.symbol,
                trade.name,
                trade.broker,
                trade.date.toIso8601String(),
                trade.side.name,
                trade.quantityMicros,
                trade.priceMicros,
                trade.totalCents,
                trade.category!.name,
                trade.dateBasis.name,
                trade.sourceMovement,
              ],
            );
          }
          database.execute('INSERT INTO report_lines VALUES (?, ?, ?)', [
            id,
            tradeId,
            isNew ? 1 : 0,
          ]);
        }
        database.execute('COMMIT');
      } catch (_) {
        database.execute('ROLLBACK');
        if (createdFile && destination.existsSync()) destination.deleteSync();
        rethrow;
      }
    } finally {
      if (temporary.existsSync()) temporary.deleteSync();
      database.close();
    }
  });
}
