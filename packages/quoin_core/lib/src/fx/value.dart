import '../calendar/day.dart';
import '../domain/ledger.dart';
import '../money/money.dart';
import 'rates.dart';
import 'to_base.dart';

/// A point-in-time price for an instrument, in [currency].
final class PriceSnapshot {
  const PriceSnapshot({
    required this.instrumentId,
    required this.price,
    required this.currency,
    required this.asOf,
  });

  final String instrumentId;
  final Money price;
  final String currency;
  final DateTime asOf;
}

final class PricesInBase {
  const PricesInBase({required this.prices, required this.unrated});

  /// Each price in euros, by instrument.
  final Map<String, PriceSnapshot> prices;

  /// The instruments whose currency has no recent rate, and that currency.
  final Map<String, String> unrated;
}

/// Every price in euros at today's rate in [zone]; one with no rate within a
/// week is set aside, never valued at an older one.
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
