import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/market_quote.dart';
import '../domain/quote_provider.dart';

class BrapiQuoteProvider implements QuoteProvider {
  BrapiQuoteProvider(this._client);
  final http.Client _client;

  @override
  Future<List<MarketQuote>> fetchQuotes(List<String> symbols) async {
    final quotes = <MarketQuote>[];
    // One symbol per request also works with the public demonstration limits.
    for (final symbol in symbols.toSet()) {
      if (!RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(symbol)) {
        throw const QuoteException('Ativo inválido para atualização.');
      }
      final response = await _client
          .get(
            Uri.https('brapi.dev', '/api/v2/stocks/quote', {'symbols': symbol}),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              throw const QuoteException(
                'A consulta demorou demais. Tente novamente.',
              );
            },
          );
      if (response.statusCode != 200) {
        throw QuoteException(switch (response.statusCode) {
          401 || 403 => 'O provedor restringiu o acesso a este ativo.',
          429 => 'Limite de consultas atingido. Tente novamente mais tarde.',
          _ => 'O provedor de cotações está indisponível.',
        });
      }
      try {
        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) throw const FormatException();
        final results = body['results'];
        if (results is! List || results.length != 1) {
          throw const FormatException();
        }
        final item = results.single;
        if (item is! Map<String, dynamic> || item['symbol'] != symbol) {
          throw const FormatException();
        }
        final data = item['data'];
        if (data is! Map<String, dynamic> || data['currency'] != 'BRL') {
          throw const FormatException();
        }
        final price = data['regularMarketPrice'];
        final time = data['regularMarketTime'];
        if (price is! num ||
            !price.isFinite ||
            price <= 0 ||
            time is! String ||
            !time.endsWith('Z')) {
          throw const FormatException();
        }
        quotes.add(
          MarketQuote(
            symbol: symbol,
            priceCents: (price * 100).round(),
            quotedAt: DateTime.parse(time).toUtc(),
            source: 'brapi',
          ),
        );
      } on FormatException {
        throw const QuoteException('O provedor retornou uma cotação inválida.');
      } on ArgumentError {
        throw const QuoteException('O provedor retornou uma cotação inválida.');
      }
    }
    return quotes;
  }
}
