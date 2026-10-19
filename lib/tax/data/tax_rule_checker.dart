import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../domain/tax_rule_status.dart';
import 'tax_sources.dart';

/// Only public documents are requested. No portfolio data leaves the machine.
class TaxRuleChecker {
  const TaxRuleChecker(this.client);
  final http.Client client;

  Future<String> _fetch(TaxSource source) async {
    final request = http.Request('GET', Uri.parse(source.url));
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 ||
        !(response.headers['content-type'] ?? '').contains('text/html')) {
      await response.stream.listen((_) {}).cancel();
      throw const FormatException('Fonte oficial indisponível.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 12),
    )) {
      bytes.add(chunk);
      if (bytes.length > 3000000) {
        throw const FormatException('Resposta oficial acima do limite.');
      }
    }
    return extractTaxArticle(utf8.decode(bytes.takeBytes()));
  }

  Future<TaxRuleStatus> check(
    TaxRuleStatus previous,
    DateTime now, {
    bool force = false,
  }) async {
    final fullCheck =
        force ||
        previous.problem != null ||
        previous.needsCheck(now) ||
        // The annual filing deadline can change well before six months elapse.
        (now.month <= 6 &&
            (previous.checkedAt == null ||
                previous.checkedAt!.year != now.year ||
                now.difference(previous.checkedAt!).inDays >= 7));
    final sources = fullCheck ? taxSources : [taxSources.first];
    var reached = 0;
    var successful = 0;
    final changed = <String>{...previous.changedSources};
    DateTime? deadline = previous.deadline;
    int? deadlineYear = previous.deadlineYear;
    await Future.wait(
      sources.map((source) async {
        try {
          final text = await _fetch(source);
          reached++;
          successful++;
          final fingerprint = sha256.convert(utf8.encode(text)).toString();
          if (source.fingerprint != fingerprint) changed.add(source.title);
          if (source.title == 'Prazo anual') {
            final parsed = parseOfficialDeadline(text, now.year);
            if (parsed != null) {
              deadline = parsed;
              deadlineYear = now.year;
            }
          }
        } on FormatException {
          reached++;
        } catch (_) {
          // Network/DNS/timeout failures keep the last successful reference.
        }
      }),
    );
    return TaxRuleStatus(
      checkedAt: fullCheck && successful == sources.length
          ? now
          : previous.checkedAt,
      attemptedAt: now,
      online: reached > 0,
      changedSources: changed.toList()..sort(),
      problem: successful < sources.length
          ? 'Não foi possível verificar todas as fontes oficiais. As regras podem estar desatualizadas.'
          : fullCheck
          ? null
          : previous.problem,
      deadlineYear: deadlineYear,
      deadline: deadline,
    );
  }
}

/// Extract only the article, excluding portal navigation and dynamic widgets.
/// Unknown markup is a failed check, never evidence that rules are unchanged.
String extractTaxArticle(String html) {
  final patterns = [
    r'<div[^>]*class="cover-richtext-tile tile-content"[^>]*>([\s\S]*?)</div>',
    r'<div[^>]*id="parent-fieldname-text(?:-[^"]*)?"[^>]*>([\s\S]*?)</div>',
    r'<div[^>]*id="form-widgets-resposta"[^>]*>([\s\S]*?)</div>',
  ];
  var text = '';
  for (final pattern in patterns) {
    text = RegExp(pattern).allMatches(html).map((m) => m[1]!).join(' ');
    if (text.isNotEmpty) break;
  }
  text = text.replaceAll(
    RegExp(r'<(script|style)\b[^>]*>[\s\S]*?</\1>', caseSensitive: false),
    '',
  );
  text = text
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+', unicode: true), ' ')
      .trim();
  if (text.length < 50) {
    throw const FormatException('Conteúdo oficial não reconhecido.');
  }
  return text;
}

/// Parse only a complete, explicitly dated annual deadline sentence.
DateTime? parseOfficialDeadline(String text, int year) {
  const months = {
    'janeiro': 1,
    'fevereiro': 2,
    'março': 3,
    'abril': 4,
    'maio': 5,
    'junho': 6,
    'julho': 7,
    'agosto': 8,
    'setembro': 9,
    'outubro': 10,
    'novembro': 11,
    'dezembro': 12,
  };
  final match = RegExp(
    'prazo para entrega da declara[çc][ãa]o do imposto de renda de $year '
    r'.*?at[ée]\s+(\d{1,2}) de ([a-zç]+) de (\d{4})',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null || int.parse(match[3]!) != year) return null;
  final month = months[match[2]!.toLowerCase()];
  final day = int.parse(match[1]!);
  if (month == null || day < 1 || day > DateTime(year, month + 1, 0).day) {
    return null;
  }
  return DateTime(year, month, day);
}
