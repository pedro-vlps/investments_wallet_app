import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../portfolio/domain/asset_category.dart';
import '../../quotes/domain/quote_credentials.dart';
import '../domain/dividend_market_data.dart';
import '../domain/dividend_payment.dart';

class BrapiDividendProvider {
  const BrapiDividendProvider(this.client, this.credentials);
  final http.Client client;
  final QuoteCredentials credentials;

  Future<Map<String, dynamic>> _get(
    String endpoint,
    Map<String, String> query,
  ) async {
    final stored = await credentials.readAccessToken();
    final token = stored == null ? null : validateQuoteAccessToken(stored);
    final response = await client
        .get(
          Uri.https('brapi.dev', endpoint, query),
          headers: token == null ? {} : {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw DividendSyncException(switch (response.statusCode) {
        400 || 403 =>
          'O plano ou o ativo não permite consultar proventos/preços originais nesse período. Confira as permissões da brapi.',
        401 => 'Configure uma chave válida em Configurar cotações.',
        429 =>
          'Limite de consultas da brapi atingido. Tente novamente mais tarde.',
        _ => 'A consulta de proventos está indisponível.',
      });
    }
    if (response.bodyBytes.length > 12 * 1024 * 1024) {
      throw const FormatException('Oversized response');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid response');
    }
    return body;
  }

  Map<String, dynamic> _stockData(Map<String, dynamic> body, String symbol) {
    final results = body['results'];
    if (results is! List ||
        results.length != 1 ||
        results.single is! Map<String, dynamic>) {
      throw const FormatException('Invalid results');
    }
    final item = results.single as Map<String, dynamic>;
    if (item['symbol'] != symbol ||
        (item['requestedSymbol'] != null &&
            item['requestedSymbol'] != symbol) ||
        item['data'] is! Map<String, dynamic>) {
      throw const FormatException('Unexpected symbol');
    }
    return item['data'] as Map<String, dynamic>;
  }

  Future<DividendMarketData> fetch(
    String symbol,
    AssetCategory category,
    DateTime start,
    DateTime asOf,
  ) async {
    if (!RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(symbol)) {
      throw const FormatException('Invalid symbol');
    }
    final warnings = <String>[];
    final announcements = <DividendAnnouncement>[];
    final closes = <String, int>{};
    var corporateActions = false;
    var announcementsUpdated = false;
    var incompleteAnnouncements = false;
    var pricesUpdated = false;
    final query = {
      'symbols': symbol,
      'startDate': start.toIso8601String().substring(0, 10),
    };
    try {
      final isFund = category == AssetCategory.realEstateFund;
      final body = await _get(
        isFund ? '/api/v2/fii/dividends' : '/api/v2/stocks/dividends',
        {...query, if (!isFund) 'includeRaw': 'true'},
      );
      final data = isFund ? body : _stockData(body, symbol);
      final items = data[isFund ? 'dividends' : 'cashDividends'];
      if (items is! List) throw const FormatException('Missing dividends');
      corporateActions =
          !isFund &&
          ((data['stockDividends'] as List? ?? []).isNotEmpty ||
              (data['subscriptions'] as List? ?? []).isNotEmpty);
      for (final value in items) {
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Invalid dividend');
        }
        if (isFund && value['symbol'] != symbol) {
          throw const FormatException('Unexpected fund');
        }
        final label = (value['label'] ?? '').toString().trim().toUpperCase();
        final kind = switch (label) {
          'DIVIDENDO' || 'DIVIDENDOS' => DividendKind.dividend,
          'JCP' ||
          'JUROS SOBRE CAPITAL PROPRIO' ||
          'JUROS SOBRE CAPITAL PRÓPRIO' => DividendKind.interestOnEquity,
          'RENDIMENTO' || 'RENDIMENTOS' => DividendKind.fundIncome,
          _ => null,
        };
        if (kind == null) {
          warnings.add(
            '$symbol: evento ${value['label']} fora do cálculo automático.',
          );
          corporateActions = true;
          continue;
        }
        if ((value['remarks'] ?? '').toString().toLowerCase().contains(
          'backfill',
        )) {
          warnings.add('$symbol: evento com datas aproximadas ignorado.');
          continue;
        }
        final rate = value[isFund ? 'rate' : 'rawRate'];
        if (rate is! num ||
            !rate.isFinite ||
            rate <= 0 ||
            rate > 100000000 ||
            value['lastDatePrior'] == null ||
            value['paymentDate'] == null) {
          warnings.add(
            '$symbol: anúncio sem valor original ou datas confirmadas ignorado.',
          );
          incompleteAnnouncements = true;
          continue;
        }
        DateTime date(Object? raw) {
          if (raw is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
            throw const FormatException('Invalid API date');
          }
          final text = raw.substring(0, 10);
          final parsed = DateTime.parse(text);
          if (parsed.toIso8601String().substring(0, 10) != text) {
            throw const FormatException('Invalid calendar date');
          }
          return parsed;
        }

        final cum = date(value['lastDatePrior']);
        final payment = date(value['paymentDate']);
        final rawEx = value['exDate'] == null ? null : date(value['exDate']);
        if (payment.isBefore(cum)) {
          throw const FormatException('Invalid dividend dates');
        }
        if ((rate * 1000000).round() <= 0) continue;
        announcements.add(
          DividendAnnouncement(
            symbol: symbol,
            kind: kind,
            paymentDate: payment,
            cumDate: cum,
            exDate: rawEx != null && rawEx.isAfter(cum) ? rawEx : null,
            perShareMicros: (rate * 1000000).round(),
          ),
        );
      }
      announcementsUpdated = !incompleteAnnouncements;
    } on DividendSyncException catch (e) {
      warnings.add('$symbol: ${e.message}');
    } catch (_) {
      warnings.add(
        '$symbol: não foi possível validar os anúncios. Dados anteriores mantidos.',
      );
      announcements.clear();
    }
    try {
      final data = _stockData(
        await _get('/api/v2/stocks/historical', {
          ...query,
          'endDate': asOf.toIso8601String().substring(0, 10),
          'interval': '1d',
          'includeRaw': 'true',
        }),
        symbol,
      );
      final items = data['historicalDataPrice'];
      if (items is! List) {
        throw const FormatException('Missing historical prices');
      }
      for (final value in items) {
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Invalid historical price');
        }
        final rate = value['rawClose'];
        final timestamp = value['date'];
        if (rate is! num || !rate.isFinite || rate <= 0 || timestamp is! int) {
          throw const FormatException('Original closing price unavailable');
        }
        final utc = DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
          isUtc: true,
        );
        final date = utc.toIso8601String().substring(0, 10);
        if (closes.containsKey(date)) {
          throw const FormatException('Duplicate daily price');
        }
        closes[date] = (rate * 100).round();
      }
      pricesUpdated = true;
    } on DividendSyncException catch (e) {
      warnings.add('$symbol: ${e.message}');
    } catch (_) {
      warnings.add(
        '$symbol: não foi possível validar os fechamentos originais. Dados anteriores mantidos.',
      );
      closes.clear();
    }
    return DividendMarketData(
      symbol: symbol,
      checkedAt: asOf,
      announcements: announcements,
      closes: closes,
      warnings: warnings.toSet().toList(),
      hasCorporateActions: corporateActions,
      announcementsUpdated: announcementsUpdated,
      pricesUpdated: pricesUpdated,
    );
  }
}
