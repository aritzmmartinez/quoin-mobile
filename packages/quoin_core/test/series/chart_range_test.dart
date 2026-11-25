import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

const madrid = 'Europe/Madrid';

PriceSnapshot close(String asOf, String price, {String currency = 'EUR'}) =>
    PriceSnapshot(
      instrumentId: 'TEST',
      price: Money.parse(price),
      currency: currency,
      asOf: DateTime.parse(asOf),
      source: 'KRAKEN',
    );

DayValue point(String day, String value) => DayValue(day, Dec.parse(value));

List<String> days(ChartWindow? window) =>
    [for (final p in window!.points) p.day];

void main() {
  group('dailyCloses', () {
    test(
        'a close is the day of its instant in the zone, across the change '
        'from summer time', () {
      // Summer time ends at 01:00 UTC on 25 October 2026: 22:30 UTC is
      // 00:30 the next day before it and 23:30 the same day after it.
      final closes = dailyCloses([
        close('2026-10-26T22:30:00Z', '4'),
        close('2026-10-23T22:30:00Z', '1'),
        close('2026-10-24T22:30:00Z', '2'),
        close('2026-10-25T22:30:00Z', '3'),
      ], madrid);
      expect(closes, [
        point('2026-10-24', '1'),
        point('2026-10-25', '3'),
        point('2026-10-26', '4'),
      ]);
    });

    test('the live quote replaces the close of its own day', () {
      final closes = dailyCloses([
        close('2026-11-20T00:00:00Z', '10'),
        close('2026-11-20T15:12:00Z', '11'),
      ], madrid);
      expect(closes, [point('2026-11-20', '11')]);
    });
  });

  group('cutRange', () {
    // Weekdays only: 30 October 2026 is a Friday, 7 November a Saturday.
    final weekdays = [
      point('2026-10-26', '90'),
      point('2026-10-27', '95'),
      point('2026-10-28', '97'),
      point('2026-10-29', '98'),
      point('2026-10-30', '100'),
      point('2026-11-02', '101'),
      point('2026-11-03', '104'),
      point('2026-11-04', '103'),
      point('2026-11-05', '108'),
      point('2026-11-06', '110'),
    ];

    test('a week back from Saturday starts at the Friday before', () {
      final week = cutRange(weekdays, ChartRange.week, '2026-11-07');
      expect(days(week), [
        '2026-10-30',
        '2026-11-02',
        '2026-11-03',
        '2026-11-04',
        '2026-11-05',
        '2026-11-06',
      ]);
      expect(week!.change, Dec.parse('10'));
      expect(week.changeRatio, Dec.parse('0.1'));
    });

    test('a cut on a day with a point starts there', () {
      final week = cutRange(weekdays, ChartRange.week, '2026-11-03');
      expect(week!.first, point('2026-10-27', '95'));
    });

    test('a period across the change from summer time counts calendar days',
        () {
      final closes = dailyCloses([
        for (var d = 20; d <= 31; d++) close('2026-10-${d}T22:30:00Z', '$d'),
      ], madrid);
      final week = cutRange(closes, ChartRange.week, '2026-11-01');
      expect(week!.first, point('2026-10-25', '25'));
      expect(week.last, point('2026-10-31', '31'));
    });

    test('with nothing that old it starts at the first point', () {
      final year = cutRange(weekdays, ChartRange.year, '2026-11-07');
      expect(year!.points, weekdays);
      expect(year.changeRatio, Dec.parse('0.222222'));
    });

    test('fewer than two points is no window', () {
      expect(cutRange([point('2026-11-06', '1')], ChartRange.max, '2026-11-07'),
          isNull);
      expect(cutRange(const [], ChartRange.max, '2026-11-07'), isNull);
    });

    test('a series with nothing in the period is no window', () {
      final stale = [point('2026-01-05', '1'), point('2026-01-06', '2')];
      expect(cutRange(stale, ChartRange.week, '2026-11-07'), isNull);
      expect(cutRange(stale, ChartRange.max, '2026-11-07'), isNotNull);
    });

    test('two points with one in the period and an old base is no window', () {
      final two = [point('2026-10-01', '1'), point('2026-11-05', '2')];
      expect(cutRange(two, ChartRange.week, '2026-11-07'), isNull);
    });

    test('two points with one in the period and a recent base is a window', () {
      final two = [point('2026-10-25', '1'), point('2026-11-05', '2')];
      expect(days(cutRange(two, ChartRange.week, '2026-11-07')), [
        '2026-10-25',
        '2026-11-05',
      ]);
    });

    test('a week after a month-long gap starts inside the week', () {
      final gap = [
        point('2026-09-28', '50'),
        point('2026-09-29', '51'),
        point('2026-11-03', '100'),
        point('2026-11-04', '102'),
        point('2026-11-06', '105'),
      ];
      final week = cutRange(gap, ChartRange.week, '2026-11-07');
      expect(days(week), ['2026-11-03', '2026-11-04', '2026-11-06']);
      expect(week!.changeRatio, Dec.parse('0.05'));
    });

    test('a zero base has a change and no ratio', () {
      final window = cutRange(
        [point('2026-11-05', '0'), point('2026-11-06', '1')],
        ChartRange.max,
        '2026-11-07',
      );
      expect(window!.change, Dec.parse('1'));
      expect(window.changeRatio, isNull);
    });
  });

  test('rangesOf offers only the periods shorter than the series', () {
    expect(rangesOf(const [], '2026-11-07'), [ChartRange.max]);
    final month = [
      for (var d = 1; d <= 30; d++)
        point('2026-11-${d.toString().padLeft(2, '0')}', '$d'),
    ];
    expect(rangesOf(month, '2026-11-30'), [ChartRange.week, ChartRange.max]);
  });

  group('lttb', () {
    final wave = [
      for (var i = 0; i < 1800; i++)
        point(
          shiftDay('2021-01-01', i),
          i == 900 ? '5000' : (i == 1200 ? '-5' : '${100 + (i % 37)}'),
        ),
    ];

    test('thins to the target and keeps the ends and the extremes', () {
      final thin = lttb(wave, 300);
      expect(thin.length, inInclusiveRange(300, 302));
      expect(thin.first, wave.first);
      expect(thin.last, wave.last);
      expect(thin, contains(wave[900]));
      expect(thin, contains(wave[1200]));
      expect(
          [for (final p in thin) p.day],
          orderedEquals([
            for (final p in thin) p.day,
          ]..sort()));
    });

    test('leaves a short series alone', () {
      expect(lttb(wave.sublist(0, 200), 300), wave.sublist(0, 200));
    });
  });

  group('historyInBase', () {
    final book = rateBookFrom([
      FxRate(
        source: 'ECB',
        base: 'EUR',
        quote: 'USD',
        day: '2026-11-02',
        rate: Dec.parse('1.25'),
      ),
    ]);

    test('converts each close at its day and counts those with no rate', () {
      final result = historyInBase([
        close('2026-10-20T20:00:00Z', '100', currency: 'USD'),
        close('2026-11-03T20:00:00Z', '100', currency: 'USD'),
        close('2026-11-04T20:00:00Z', '7'),
      ], book, madrid);
      expect(result.unrated, 1);
      expect([
        for (final s in result.history) s.price
      ], [
        Money.parse('80'),
        Money.parse('7'),
      ]);
      expect(result.history.first.source, 'KRAKEN');
    });
  });
}
