import '../calendar/target.dart';
import '../decimal/dec.dart';
import '../money/money.dart';
import '../series/as_of.dart';
import '../sort.dart';

const int valuationRateMaxAgeDays = 7;

/// A published exchange rate: units of [quote] per one [base] on [day].
final class FxRate {
  const FxRate({
    required this.source,
    required this.base,
    required this.quote,
    required this.day,
    required this.rate,
  });

  final String source;
  final String base;
  final String quote;

  /// `YYYY-MM-DD`, the source's reference date.
  final String day;
  final Dec rate;
}

/// Each currency's rates against the euro, oldest first.
typedef RateBook = Map<String, List<FxRate>>;

RateBook rateBookFrom(Iterable<FxRate> rates) {
  final byQuote = <String, List<FxRate>>{};
  for (final rate in rates) {
    if (rate.base != baseCurrency) {
      throw ArgumentError(
        'A rate book is against $baseCurrency, '
        'got ${rate.base}:${rate.quote} on ${rate.day}',
      );
    }
    byQuote.putIfAbsent(rate.quote, () => []).add(rate);
  }
  return {
    for (final MapEntry(key: quote, value: series) in byQuote.entries)
      quote: _checked(
          quote, stableSorted(series, (a, b) => a.day.compareTo(b.day))),
  };
}

List<FxRate> _checked(String quote, List<FxRate> series) {
  for (var i = 1; i < series.length; i += 1) {
    if (series[i].day == series[i - 1].day) {
      throw ArgumentError('Two rates for $quote on ${series[i].day}');
    }
  }
  return series;
}

/// The rate a ledger row of [day] is booked at: that TARGET day's, or none.
FxRate? bookingRate(RateBook book, String currency, String day) {
  final series = book[currency];
  if (series == null) return null;
  final wanted = rateDayFor(day);
  final found = onOrBeforeDay(series, (rate) => rate.day, wanted, 0);
  return found?.day == wanted ? found : null;
}

/// The rate a price of [day] is valued at: the last one published on or before
/// it, at most a week old.
FxRate? valuationRate(RateBook book, String currency, String day) {
  final series = book[currency];
  if (series == null) return null;
  return onOrBeforeDay(
    series,
    (rate) => rate.day,
    day,
    valuationRateMaxAgeDays,
  );
}
