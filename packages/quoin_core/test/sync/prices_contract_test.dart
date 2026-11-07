import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

typedef Json = Map<String, Object?>;

List<PriceRow> rowsOf(Object? raw) => [
      for (final row in (raw! as List<Object?>).cast<Json>())
        PriceRow(
          asOf: row['asOf']! as String,
          price: row['price']! as String,
          currency: row['currency']! as String,
          source: row['source']! as String,
        ),
    ];

List<Json> plain(List<PriceRow> rows) => [for (final r in rows) r.toJson()];

void main() {
  final contract = jsonDecode(
    File('test/contract/sync-prices.json').readAsStringSync(),
  ) as Json;

  group('sync prices contract', () {
    for (final raw in contract['cases']! as List<Object?>) {
      final c = raw! as Json;
      final stored = c['stored']! as Json;
      final storedRows = rowsOf(stored['rows']);
      final holding = c['holding']! as Json;
      final last = holding['last'] as String?;
      final sameVersion = holding['seriesVersion'] != null &&
          holding['seriesVersion'] == stored['seriesVersion'];
      final held = sameVersion && last != null
          ? [
              for (final row in storedRows)
                if (!row.instant.isAfter(DateTime.parse(last))) row,
            ]
          : [
              const PriceRow(
                asOf: '2026-09-01T07:00:00.000Z',
                price: '1',
                currency: 'EUR',
                source: 'OTHER',
              ),
            ];

      test(c['name']! as String, () {
        final expected = c['expect']! as Json;
        final answer = parsePriceAnswer(expected);
        expect(answer.instrumentId, holding['instrumentId']);
        final after = applyPriceAnswer(held, answer);

        switch (answer) {
          case PendingPrices():
            expect(c['pending'], isTrue);
            expect(plain(after), plain(held));
          case FullPrices(:final seriesVersion):
            expect(seriesVersion, expected['seriesVersion']);
            expect(plain(after), expected['rows']);
          case TailPrices(:final seriesVersion):
            expect(seriesVersion, stored['seriesVersion']);
            expect(plain(after), plain(storedRows));
        }
      });
    }
  });

  group('holdingOf', () {
    const row = PriceRow(
      asOf: '2026-10-13T09:00:00+02:00',
      price: '10',
      currency: 'EUR',
      source: 'YAHOO',
    );

    test('a phone with nothing sends null for both', () {
      expect(holdingOf('I', 'series-a', const []).toJson(), {
        'instrumentId': 'I',
        'seriesVersion': null,
        'last': null,
      });
    });

    test('last is the newest instant, whatever its offset, as written', () {
      const later = PriceRow(
        asOf: '2026-10-13T08:00:00.000Z',
        price: '10',
        currency: 'EUR',
        source: 'YAHOO',
      );
      expect(holdingOf('I', 'series-a', [later, row]).toJson(), {
        'instrumentId': 'I',
        'seriesVersion': 'series-a',
        'last': '2026-10-13T08:00:00.000Z',
      });
    });
  });

  group('parsePriceAnswer refuses', () {
    for (final (name, raw) in [
      ('an unknown kind', {'instrumentId': 'I', 'kind': 'some'}),
      (
        'a full answer with no version',
        {'instrumentId': 'I', 'kind': 'full', 'rows': <Object?>[]}
      ),
      (
        'a price that is not a decimal',
        {
          'instrumentId': 'I',
          'kind': 'full',
          'seriesVersion': 'v',
          'rows': [
            {
              'asOf': '2026-10-13T07:00:00.000Z',
              'price': 'ten',
              'currency': 'EUR',
              'source': 'YAHOO'
            },
          ],
        }
      ),
      (
        'a tail with no from',
        {
          'instrumentId': 'I',
          'kind': 'tail',
          'seriesVersion': 'v',
          'rows': <Object?>[]
        }
      ),
    ]) {
      test(name, () {
        expect(() => parsePriceAnswer(raw), throwsA(isA<InvalidPriceAnswer>()));
      });
    }
  });
}
