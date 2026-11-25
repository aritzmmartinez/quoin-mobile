import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

DateTime at(String iso) => DateTime.parse(iso);

KrakenQuote quote(String asOf, [String price = '1']) => KrakenQuote(
      symbol: 'BTC/EUR',
      price: price,
      currency: 'EUR',
      asOf: at(asOf),
    );

void main() {
  final now = at('2026-11-21T10:00:00Z');

  group('planKrakenStep', () {
    test('no pair leaves an instrument and drops a Kraken series', () {
      expect(planKrakenStep(null, const NoOrigin(), now), isA<KrakenLeave>());
      expect(
        planKrakenStep(null, PcOrigin(at('2026-11-20T00:00Z')), now),
        isA<KrakenLeave>(),
      );
      expect(
        planKrakenStep(null, KrakenOrigin('BTC/EUR', null), now),
        isA<KrakenDrop>(),
      );
    });

    test('a PC series up to date is left alone', () {
      final step = planKrakenStep(
        'BTC/EUR',
        PcOrigin(at('2026-11-13T00:00Z')),
        now,
      );
      expect(step, isA<KrakenLeave>());
    });

    test('a PC series with no candle in over 7 days goes to Kraken whole', () {
      for (final origin in [
        PcOrigin(at('2026-11-12T00:00Z')),
        const PcOrigin(null),
      ]) {
        expect(
          planKrakenStep('BTC/EUR', origin, now),
          isA<KrakenFull>().having((s) => s.symbol, 'symbol', 'BTC/EUR'),
        );
      }
    });

    test('nothing stored, or another pair, is a full download', () {
      expect(
          planKrakenStep('BTC/EUR', const NoOrigin(), now), isA<KrakenFull>());
      expect(
        planKrakenStep(
          'BTC/EUR',
          KrakenOrigin('XBT/EUR', at('2026-11-20T00:00Z')),
          now,
        ),
        isA<KrakenFull>(),
      );
    });

    test('the same pair asks from a week before its newest candle', () {
      expect(
        planKrakenStep(
          'BTC/EUR',
          KrakenOrigin('BTC/EUR', at('2026-11-17T00:00Z')),
          now,
        ),
        isA<KrakenTail>()
            .having((s) => s.since, 'since', at('2026-11-10T00:00Z')),
      );
    });

    test('with yesterday stored only the live quote is asked', () {
      expect(
        planKrakenStep(
          'BTC/EUR',
          KrakenOrigin('BTC/EUR', at('2026-11-20T00:00Z')),
          now,
        ),
        isA<KrakenTail>().having((s) => s.since, 'since', isNull),
      );
    });
  });

  group('planKrakenWrite', () {
    test('the candle of a day removes that day\'s live row', () {
      final write = planKrakenWrite(
        [
          StoredPrice(at('2026-11-19T00:00Z'), live: false),
          StoredPrice(at('2026-11-20T15:00Z'), live: true),
        ],
        [quote('2026-11-20T00:00Z')],
        null,
      );
      expect(write.remove, [at('2026-11-20T15:00Z')]);
      expect(write.candles, hasLength(1));
      expect(write.live, isNull);
    });

    test('a new live quote replaces the old one', () {
      final live = quote('2026-11-21T09:00Z');
      final write = planKrakenWrite(
        [
          StoredPrice(at('2026-11-20T00:00Z'), live: false),
          StoredPrice(at('2026-11-21T08:00Z'), live: true),
        ],
        const [],
        live,
      );
      expect(write.remove, [at('2026-11-21T08:00Z')]);
      expect(write.live, same(live));
    });

    test('a live quote on a day with a candle is not kept', () {
      final write = planKrakenWrite(
        const [],
        [quote('2026-11-20T00:00Z')],
        quote('2026-11-20T23:00Z'),
      );
      expect(write.live, isNull);
    });

    test('a corrected candle replaces the stored one of its day', () {
      final write = planKrakenWrite(
        [StoredPrice(at('2026-11-19T00:00Z'), live: false)],
        [quote('2026-11-19T00:00Z', '2')],
        null,
      );
      expect(write.remove, [at('2026-11-19T00:00Z')]);
    });
  });

  test('isStaleSeries counts from yesterday\'s candle', () {
    expect(isStaleSeries(at('2026-11-13T00:00Z'), now), isFalse);
    expect(isStaleSeries(at('2026-11-12T00:00Z'), now), isTrue);
    expect(isStaleSeries(null, now), isTrue);
  });
}
