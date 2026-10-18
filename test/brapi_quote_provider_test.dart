import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investments_wallet/quotes/data/brapi_quote_provider.dart';
import 'package:investments_wallet/quotes/domain/quote_provider.dart';

String responseBody({
  String symbol = 'PETR4',
  Object price = 59.68,
  String currency = 'BRL',
  String time = '2026-10-16T21:30:30Z',
}) => jsonEncode({
  'results': [
    {
      'symbol': symbol,
      'data': {
        'currency': currency,
        'regularMarketPrice': price,
        'regularMarketTime': time,
      },
    },
  ],
});

void main() {
  test('reads v2 quotes, preserves timestamp, and converts to cents', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'brapi.dev');
      expect(request.url.path, '/api/v2/stocks/quote');
      expect(request.url.queryParameters['symbols'], 'PETR4');
      return http.Response(responseBody(), 200);
    });
    addTearDown(client.close);
    final quote = (await BrapiQuoteProvider(
      client,
    ).fetchQuotes(['PETR4'])).single;
    expect(quote.priceCents, 5968);
    expect(quote.quotedAt, DateTime.utc(2026, 10, 16, 21, 30, 30));
  });

  for (final body in [
    responseBody(symbol: 'VALE3'),
    responseBody(price: -1),
    responseBody(currency: 'USD'),
    responseBody(time: 'invalid'),
    '{',
    '{"results": []}',
  ]) {
    test('rejects malformed or mismatched response: $body', () async {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      await expectLater(
        BrapiQuoteProvider(client).fetchQuotes(['PETR4']),
        throwsA(isA<QuoteException>()),
      );
    });
  }

  test('reports rate limiting without returning false success', () async {
    final client = MockClient((_) async => http.Response('', 429));
    addTearDown(client.close);
    await expectLater(
      BrapiQuoteProvider(client).fetchQuotes(['PETR4']),
      throwsA(
        isA<QuoteException>().having(
          (error) => error.message,
          'message',
          contains('Limite'),
        ),
      ),
    );
  });
}
