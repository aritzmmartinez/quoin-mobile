import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

typedef Json = Map<String, Object?>;

Object? _plain(KrakenReading<Object?> reading) => switch (reading) {
      KrakenRead(value: final List<KrakenQuote> quotes) => {
          'ok': true,
          'value': [for (final q in quotes) q.toJson()],
        },
      KrakenRead(value: final KrakenQuote quote) => {
          'ok': true,
          'value': quote.toJson(),
        },
      KrakenRead() => {'ok': true, 'value': null},
      KrakenError(:final error) => {'ok': false, 'error': error},
    };

Object? _evaluate(Json c) {
  List<String> list(String key) => (c[key]! as List<Object?>).cast<String>();
  return switch (c['read']) {
    'ohlc' => _plain(readKrakenOhlc(c['answer'], c['symbol']! as String)),
    'trade' => _plain(readKrakenTrade(c['answer'], c['symbol']! as String)),
    'symbolFor' => {
        for (final code in list('codes')) code: krakenSymbolFor(code)
      },
    'sourceOf' => {
        for (final s in list('symbols')) s: quoteSourceOf(s).name.toUpperCase(),
      },
    final read => throw StateError('read $read'),
  };
}

void main() {
  final contract = jsonDecode(
    File('test/contract/kraken.json').readAsStringSync(),
  ) as Json;
  final cases = (contract['cases']! as List<Object?>).cast<Json>();

  test('the contract has its 13 cases', () => expect(cases, hasLength(13)));

  for (final c in cases) {
    test(c['name']! as String, () => expect(_evaluate(c), c['expect']));
  }

  group('effectiveKrakenSymbol', () {
    test('a pair the user chose wins', () {
      expect(
        effectiveKrakenSymbol(
            type: 'CRYPTO', id: 'BTC', quoteSymbol: 'XBT/USD'),
        'XBT/USD',
      );
    });

    test('a crypto without a pair takes the suggested one', () {
      expect(
        effectiveKrakenSymbol(type: 'CRYPTO', id: 'USDG', quoteSymbol: null),
        'USDG/USD',
      );
    });

    test('a Yahoo symbol on a crypto falls back to the suggested pair', () {
      expect(
        effectiveKrakenSymbol(
            type: 'CRYPTO', id: 'BTC', quoteSymbol: 'BTC-EUR'),
        'BTC/EUR',
      );
    });

    test('anything else has no pair', () {
      expect(
        effectiveKrakenSymbol(
            type: 'ETF', id: 'IE00TEST0001', quoteSymbol: null),
        isNull,
      );
      expect(
        effectiveKrakenSymbol(
          type: 'ETF',
          id: 'IE00TEST0001',
          quoteSymbol: 'VWCE.DE',
        ),
        isNull,
      );
    });
  });
}
