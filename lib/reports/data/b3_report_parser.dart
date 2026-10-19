import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../portfolio/domain/asset_category.dart';
import '../domain/report_document.dart';
import '../domain/report_trade.dart';
import 'b3_listed_asset.dart';
import 'b3_value_parser.dart';

class B3ReportParser {
  static const maxBytes = 10 * 1024 * 1024;
  static const maxRows = 50000;

  ParsedReport parse(String name, Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const ReportImportException(
        'Escolha um arquivo de até 10 MB, não vazio.',
      );
    }
    try {
      final tables = <String, List<List<Object?>>>{};
      if (name.toLowerCase().endsWith('.xlsx')) {
        final archive = ZipDecoder().decodeBytes(bytes);
        if (archive.length > 1000 ||
            archive.fold<int>(0, (sum, f) => sum + f.size) > 50 * 1024 * 1024) {
          throw const ReportImportException(
            'Planilha muito grande após descompactação (máximo 50 MB).',
          );
        }
        final workbook = Excel.decodeBytes(bytes);
        for (final sheet in workbook.tables.values) {
          if (sheet.maxRows > maxRows || sheet.maxColumns > 128) {
            throw const ReportImportException(
              'Limite de 50 mil linhas ou 128 colunas excedido.',
            );
          }
          tables[sheet.sheetName] = sheet.rows
              .map((row) => row.map((cell) => _value(cell?.value)).toList())
              .toList();
        }
      } else if (name.toLowerCase().endsWith('.csv')) {
        String text;
        try {
          text = utf8.decode(bytes);
        } on FormatException {
          text = latin1.decode(bytes);
        }
        text = text.replaceFirst('\uFEFF', '');
        final rows = Csv().decode(text);
        if (rows.length > maxRows || rows.any((r) => r.length > 128)) {
          throw const ReportImportException(
            'Limite de 50 mil linhas ou 128 colunas excedido.',
          );
        }
        tables['CSV'] = rows.map((r) => r.cast<Object?>()).toList();
      } else {
        throw const ReportImportException(
          'Use o Excel (.xlsx) de Negociação ou Movimentação da B3, ou CSV. PDF e XLS não são aceitos nesta versão.',
        );
      }
      return _tables(tables);
    } on ReportImportException {
      rethrow;
    } catch (_) {
      throw const ReportImportException(
        'Não foi possível ler a planilha. Verifique se é um XLSX ou CSV válido, sem senha.',
      );
    }
  }

  Object? _value(CellValue? value) => switch (value) {
    null => null,
    IntCellValue() => value.value,
    DoubleCellValue() => value.value,
    DateCellValue() => value.asDateTimeLocal(),
    DateTimeCellValue() => value.asDateTimeLocal(),
    FormulaCellValue() => null,
    _ => value.toString(),
  };

  ParsedReport _tables(Map<String, List<List<Object?>>> tables) {
    final trades = <ReportTrade>[];
    final issues = <ReportIssue>[];
    final layouts = <String>{};
    var dataRows = 0;
    for (final table in tables.entries) {
      Map<String, int>? columns;
      var negotiation = false;
      for (var index = 0; index < table.value.length; index++) {
        final row = table.value[index];
        final headers = {
          for (var c = 0; c < row.length; c++) normalizeB3Text(row[c]): c,
        };
        if (headers.containsKey('data do negocio') ||
            (headers.containsKey('movimentacao') &&
                headers.containsKey('produto'))) {
          negotiation = headers.containsKey('data do negocio');
          final required = negotiation
              ? [
                  'data do negocio',
                  'tipo de movimentacao',
                  'mercado',
                  'instituicao',
                  'codigo de negociacao',
                  'quantidade',
                  'preco',
                  'valor',
                ]
              : [
                  'entrada/saida',
                  'data',
                  'movimentacao',
                  'produto',
                  'instituicao',
                  'quantidade',
                  'preco unitario',
                  'valor da operacao',
                ];
          final missing = required
              .where((h) => !headers.containsKey(h))
              .toList();
          if (missing.isNotEmpty) {
            throw ReportImportException(
              'Colunas ausentes: ${missing.join(', ')}.',
            );
          }
          columns = headers;
          layouts.add(negotiation ? 'Negociação' : 'Movimentação');
          continue;
        }
        if (columns == null ||
            row.every((v) => v == null || v.toString().trim().isEmpty)) {
          continue;
        }
        dataRows++;
        if (dataRows > maxRows) {
          throw const ReportImportException(
            'Limite total de 50 mil linhas excedido.',
          );
        }
        final location = '${table.key}, linha ${index + 1}';
        Object? cell(String key) {
          final column = columns![key];
          return column == null || column >= row.length ? null : row[column];
        }

        String string(String key) => (cell(key) ?? '').toString().trim();
        final movement = normalizeB3Text(
          cell(negotiation ? 'tipo de movimentacao' : 'movimentacao'),
        );
        if (movement != 'compra' && movement != 'venda') {
          issues.add(
            ReportIssue(
              location,
              movement == 'transferencia - liquidacao'
                  ? 'Liquidação ignorada: use Negociação para evitar contar a mesma compra duas vezes.'
                  : 'Evento não importado: ${string(negotiation ? 'tipo de movimentacao' : 'movimentacao')}.',
            ),
          );
          continue;
        }
        if (negotiation &&
            ![
              'mercado a vista',
              'mercado fracionario',
              'a vista',
              'fracionario',
            ].contains(normalizeB3Text(cell('mercado')))) {
          issues.add(
            ReportIssue(
              location,
              'Mercado fora do escopo: ${string('mercado')}.',
            ),
          );
          continue;
        }
        final product = string(
          negotiation ? 'codigo de negociacao' : 'produto',
        );
        final normalizedProduct = normalizeB3Text(product);
        final treasury = RegExp(
          r'^tesouro (selic|prefixado|ipca|renda|educa)',
        ).hasMatch(normalizedProduct);
        var symbol = product
            .split(RegExp(r'\s+-\s+'))
            .first
            .trim()
            .toUpperCase();
        if (!treasury) {
          symbol = normalizeB3ListedSymbol(symbol);
        }
        if (!treasury && !isSupportedB3ListedSymbol(symbol)) {
          issues.add(
            ReportIssue(
              location,
              'Ativo fora do escopo ou não identificado: $product.',
            ),
          );
          continue;
        }
        final categoryText = normalizeB3Text(
          '${string('tipo de produto')} ${string('tipo de ativo')} ${table.key}',
        );
        final category = treasury
            ? AssetCategory.treasury
            : classifyB3ListedAsset(symbol, categoryText);
        if (treasury) {
          symbol =
              'TD${sha256.convert(utf8.encode(normalizedProduct)).toString().substring(0, 10).toUpperCase()}';
        }
        try {
          final quantity = parseB3Scaled(cell('quantidade'), 1000000);
          final price = parseB3Scaled(
            cell(negotiation ? 'preco' : 'preco unitario'),
            1000000,
          );
          final total = parseB3Scaled(
            cell(negotiation ? 'valor' : 'valor da operacao'),
            100,
          );
          final broker = string(
            'instituicao',
          ).replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
          if (broker.isEmpty || (!treasury && quantity % 1000000 != 0)) {
            throw const FormatException('Invalid quantity or broker');
          }
          final expectedTotal = quantity / 1000000 * price / 10000;
          if ((expectedTotal - total).abs() > 2) {
            throw const FormatException('Inconsistent total');
          }
          if (!negotiation) {
            final direction = normalizeB3Text(cell('entrada/saida'));
            final valid = movement == 'compra'
                ? ['credito', 'entrada']
                : ['debito', 'saida'];
            if (!valid.contains(direction)) {
              throw const FormatException('Inconsistent direction');
            }
          }
          trades.add(
            ReportTrade(
              symbol: symbol,
              name: product,
              broker: broker,
              date: parseB3Date(cell(negotiation ? 'data do negocio' : 'data')),
              side: movement == 'compra' ? TradeSide.buy : TradeSide.sell,
              quantityMicros: quantity,
              priceMicros: price,
              totalCents: total,
              location: location,
              category: category,
            ),
          );
        } on FormatException {
          throw ReportImportException(
            '$location: data, instituição, quantidade ou valores inválidos. Nenhuma linha deste arquivo foi gravada.',
          );
        }
      }
    }
    if (layouts.isEmpty) {
      throw const ReportImportException(
        'Layout não reconhecido. Exporte Negociação ou Movimentação da Área do Investidor B3. Relatórios de Posição e notas de corretagem não são aceitos nesta versão.',
      );
    }
    return ParsedReport(trades: trades, issues: issues, layouts: layouts);
  }
}
