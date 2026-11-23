import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

const series = (source: 'ECB', base: 'EUR', quote: 'USD');

FxRate usd(String day, String rate) => FxRate(
      source: 'ECB',
      base: 'EUR',
      quote: 'USD',
      day: day,
      rate: Dec.parse(rate),
    );

void main() {
  test('new days are written, oldest first; equal ones are unchanged', () {
    final plan = planFxWrite(
      series,
      [usd('2026-03-02', '1.08')],
      [
        usd('2026-03-04', '1.09'),
        usd('2026-03-02', '1.080'),
        usd('2026-03-03', '1.1')
      ],
    );
    expect(plan.write.map((r) => r.day), ['2026-03-03', '2026-03-04']);
    expect(plan.unchanged, 1);
    expect(plan.conflicts, isEmpty);
  });

  test('a day that disagrees writes nothing for the series', () {
    final plan = planFxWrite(
      series,
      [usd('2026-03-02', '1.08')],
      [usd('2026-03-02', '1.07'), usd('2026-03-03', '1.1')],
    );
    expect(plan.write, isEmpty);
    expect(plan.conflicts.single.stored.rate, Dec.parse('1.08'));
    expect(plan.conflicts.single.incoming.rate, Dec.parse('1.07'));
  });

  test('a repeated day in one fetch is compared with itself', () {
    final plan = planFxWrite(
      series,
      const [],
      [usd('2026-03-02', '1.08'), usd('2026-03-02', '1.08')],
    );
    expect(plan.write, hasLength(1));
    expect(plan.unchanged, 1);
  });

  test('a rate of another series is refused', () {
    expect(
      () => planFxWrite(series, const [], [
        FxRate(
          source: 'ECB',
          base: 'EUR',
          quote: 'GBP',
          day: '2026-03-02',
          rate: Dec.parse('0.85'),
        ),
      ]),
      throwsArgumentError,
    );
  });
}
