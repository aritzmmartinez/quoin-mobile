import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

FxRate usd(String day, [String rate = '1.1']) => FxRate(
      source: 'ECB',
      base: 'EUR',
      quote: 'USD',
      day: day,
      rate: Dec.parse(rate),
    );

TradeEvent trade({
  String fees = '1',
  String currency = 'EUR',
  FxSource fxSource = FxSource.identity,
  String? fxRate,
  FxDirection? fxDirection,
}) =>
    TradeEvent(
      id: 't1',
      ts: DateTime.utc(2026, 4, 2, 10),
      type: TradeType.buy,
      instrumentId: 'US00TEST0001',
      quantity: Dec.parse('10'),
      price: Money.parse('100'),
      grossAmount: Money.parse('1001'),
      fees: Money.parse(fees),
      currency: currency,
      fxSource: fxSource,
      fxRate: fxRate == null ? null : Dec.parse(fxRate),
      fxDirection: fxDirection,
      account: 'test',
      source: 'TEST',
    );

void main() {
  // Good Friday is 3 April 2026 and Easter Monday 6 April, both TARGET
  // closing days: the ECB publishes on Thursday 2 and again on Tuesday 7.
  final easter = rateBookFrom([usd('2026-04-07'), usd('2026-04-02', '1.08')]);

  group('rate book', () {
    test('sorts each currency by day', () {
      expect(easter['USD']!.map((r) => r.day), ['2026-04-02', '2026-04-07']);
    });

    test('refuses two rates for one currency on one day', () {
      expect(
        () => rateBookFrom([usd('2026-04-02'), usd('2026-04-02', '1.2')]),
        throwsArgumentError,
      );
    });

    test('a ledger row books at its own TARGET day, never an older one', () {
      expect(bookingRate(easter, 'USD', '2026-04-06')?.day, '2026-04-02');
      expect(bookingRate(easter, 'USD', '2026-04-08'), isNull);
    });

    test('a price values at the last rate, at most a week old', () {
      expect(valuationRate(easter, 'USD', '2026-04-08')?.day, '2026-04-07');
      expect(valuationRate(easter, 'USD', '2026-04-14')?.day, '2026-04-07');
      expect(valuationRate(easter, 'USD', '2026-04-15'), isNull);
      expect(valuationRate(easter, 'USD', '2026-04-01'), isNull);
    });
  });

  group('toBase', () {
    String? base(TradeEvent event, Money amount) =>
        toBase(event, amount)?.toString();
    TradeEvent ecb(String rate, {String fees = '1'}) => trade(
          fees: fees,
          currency: 'USD',
          fxSource: FxSource.ecb,
          fxRate: rate,
          fxDirection: FxDirection.quotePerBase,
        );

    test('rounds a converted amount to the cent, half up', () {
      final halfCent = ecb('2', fees: '0.01');
      expect(base(halfCent, halfCent.fees), '0.01');
      final tiny = ecb('2', fees: '0.009');
      expect(base(tiny, tiny.fees), '0');
    });

    test('multiplies a rate quoted as euros per unit', () {
      final event = trade(
        currency: 'USD',
        fxSource: FxSource.ecb,
        fxRate: '0.9',
        fxDirection: FxDirection.basePerQuote,
      );
      expect(base(event, event.grossAmount), '900.9');
    });

    test('answers no rate for a foreign row booked as it stands', () {
      final event = trade(currency: 'USD');
      expect(base(event, event.grossAmount), isNull);
      expect(() => baseOf(event, event.grossAmount), throwsStateError);
    });
  });

  test('a swap with no rule in force keeps each leg at its own value', () {
    Money m(String v) => Money.parse(v);
    final pair = swapPairValue(
      SwapSides(
        deliveredValue: m('600'),
        receivedValue: m('605'),
        receivedFee: m('25'),
      ),
      null,
    );
    expect('${pair.sell.gross} ${pair.sell.fees}', '600 0');
    expect('${pair.buy.gross} ${pair.buy.fees}', '580 0');
  });

  test('stableSorted keeps equal items in input order', () {
    expect(
      stableSorted(['b1', 'a1', 'b2', 'a2'], (x, y) => x[0].compareTo(y[0])),
      ['a1', 'a2', 'b1', 'b2'],
    );
  });

  test('toFixed pads and keeps the sign of a negative zero', () {
    expect(Dec.parse('1').toFixed(6), '1.000000');
    expect(Dec.parse('-0.0000001').toFixed(6), '-0.000000');
    expect(Dec.parse('-0.0000005').toFixed(6), '-0.000001');
  });
}
