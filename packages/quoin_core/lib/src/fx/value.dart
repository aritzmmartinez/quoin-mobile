import '../calendar/day.dart';
import '../domain/ledger.dart';
import '../money/money.dart';
import 'rates.dart';
import 'to_base.dart';

final class PriceSnapshot {
  const PriceSnapshot({
    required this.instrumentId,
    required this.price,
    required this.currency,
    required this.asOf,
    this.source = 'YAHOO',
  });

  final String instrumentId;
  final Money price;
  final String currency;
  final DateTime asOf;
  final String source;
}

DateTime snapshotKnownAt(PriceSnapshot snapshot) =>
    snapshot.source.endsWith('_LIVE')
        ? snapshot.asOf
        : snapshot.asOf.add(const Duration(days: 1));

final class PricesInBase {
  const PricesInBase({required this.prices, required this.unrated});

  final Map<String, PriceSnapshot> prices;

  final Map<String, String> unrated;
}

PricesInBase pricesInBase(
  Map<String, PriceSnapshot> prices,
  RateBook book,
  DateTime now,
  String zone,
) {
  final day = dayOf(now, zone);
  final converted = <String, PriceSnapshot>{};
  final unrated = <String, String>{};
  for (final MapEntry(key: instrumentId, value: price) in prices.entries) {
    final based = _inBase(price, book, day);
    if (based == null) {
      unrated[instrumentId] = price.currency;
    } else {
      converted[instrumentId] = based;
    }
  }
  return PricesInBase(prices: converted, unrated: unrated);
}

PriceSnapshot? _inBase(PriceSnapshot price, RateBook book, String day) {
  if (price.currency == baseCurrency) return price;
  final rate = valuationRate(book, price.currency, day);
  if (rate == null) return null;
  return PriceSnapshot(
    instrumentId: price.instrumentId,
    price: inBase(
        price.price, price.currency, rate.rate, FxDirection.quotePerBase),
    currency: baseCurrency,
    asOf: price.asOf,
  );
}
