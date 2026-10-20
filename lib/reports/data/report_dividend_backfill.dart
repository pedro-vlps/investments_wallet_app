import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import '../../dividends/data/reported_dividend_store.dart';
import '../domain/report_trade.dart';
import 'b3_report_parser.dart';

/// Recover formerly ignored cash credits once from immutable local originals.
void backfillReportDividends(Database db, String reportDirectory) {
  final reports = db.select(
    '''SELECT id, name, issues_json FROM imported_reports
    WHERE id NOT IN (SELECT report_id FROM report_dividend_imports)''',
  );
  for (final report in reports) {
    final id = report['id'] as String;
    final extension = path.extension(report['name'] as String).toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id) ||
        !['.xlsx', '.csv'].contains(extension)) {
      throw const ReportImportException(
        'Referência de relatório inválida na pasta de backup.',
      );
    }
    final file = File(path.join(reportDirectory, '$id$extension'));
    if (!file.existsSync() || file.lengthSync() > B3ReportParser.maxBytes) {
      throw const ReportImportException(
        'Não foi possível recuperar os proventos de um relatório salvo. Verifique os arquivos originais na pasta de backup.',
      );
    }
    final bytes = file.readAsBytesSync();
    if (sha256.convert(bytes).toString() != id) {
      throw const ReportImportException(
        'O arquivo original de um relatório foi alterado. Restaure o backup para recuperar os proventos.',
      );
    }
    final parsed = B3ReportParser().parse(report['name'] as String, bytes);
    db.execute('BEGIN IMMEDIATE');
    try {
      if (db.select(
        'SELECT 1 FROM report_dividend_imports WHERE report_id = ?',
        [id],
      ).isEmpty) {
        ReportedDividendStore.save(db, id, parsed.dividends);
        final recovered = parsed.dividends.map((p) => p.location).toSet();
        final issues = (jsonDecode(report['issues_json'] as String) as List)
            .where(
              (issue) =>
                  !(recovered.contains(issue['location']) &&
                      (issue['reason'] as String).startsWith(
                        'Evento não importado:',
                      )),
            )
            .toList();
        db.execute('UPDATE imported_reports SET issues_json = ? WHERE id = ?', [
          jsonEncode(issues),
          id,
        ]);
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}
