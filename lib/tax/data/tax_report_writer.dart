import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../financial_display/number_format.dart';
import '../domain/tax_assessment.dart';

class TaxReportWriter {
  const TaxReportWriter(this.dataDirectory);
  final String dataDirectory;

  Future<String> write(
    Map<String, Object?> report,
    List<TaxAssessment> assessments,
  ) async {
    const escape = HtmlEscape();
    final year = report['calendarYear'] as int;
    final directory = Directory(path.join(dataDirectory, 'tax', 'exports'));
    await directory.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final destination = path.join(
      directory.path,
      'IRPF-${year + 1}-$stamp.html',
    );
    final json = const JsonEncoder.withIndent('  ').convert(report);
    final rows = assessments
        .map(
          (a) =>
              '<tr><td>${a.input.month}/$year</td>'
              '<td>${formatMoney(a.exemptGain)}</td><td>${formatMoney(a.darf)}</td>'
              '<td>${formatMoney(a.input.paid)}</td><td>${a.complete ? 'Revisado' : 'Parcial'}</td></tr>',
        )
        .join();
    final html =
        '''<!doctype html><html lang="pt-BR"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Demonstrativo auxiliar IRPF ${year + 1}</title>
<style>body{font:16px system-ui;margin:32px;max-width:1100px}table{border-collapse:collapse;width:100%}td,th{border:1px solid #aaa;padding:8px;text-align:left}pre{white-space:pre-wrap;overflow-wrap:anywhere}</style>
<h1>Demonstrativo auxiliar de investimentos — IRPF ${year + 1}</h1>
<p><strong>${report['twelveMonthsReviewed'] == true ? 'Os 12 meses e os saldos iniciais foram registrados.' : 'DEMONSTRATIVO PARCIAL: faltam meses ou saldos iniciais. Não trate pendências como ausência de imposto.'}</strong></p>
<p>Ano-calendário $year. Este arquivo não é uma declaração pronta para entrega, não é importável no PGD e não foi transmitido à Receita.</p>
<p>Confira os dados no Meu Imposto de Renda/ReVar, os informes das instituições e os custos fiscais de aquisição. As operações B3 abaixo são referências brutas para conciliação.</p>
<p>Meses ausentes não significam ausência de imposto. Resultados parciais não confirmam quitação. Juros e multas não estão calculados.</p>
<table><thead><tr><th>Mês</th><th>Ganho isento</th><th>DARF principal</th><th>Principal informado como pago</th><th>Histórico</th></tr></thead><tbody>$rows</tbody></table>
<h2>Dados e pendências para conferência</h2><pre>${escape.convert(json)}</pre></html>''';
    await File(destination).writeAsString(html, flush: true);
    return destination;
  }
}
