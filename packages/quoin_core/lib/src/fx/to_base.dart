import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../money/money.dart';

const int baseDecimals = 2;

/// [value] in [currency], in euros at [rate] quoted in [direction].
Money inBase(Money value, String currency, Dec rate, FxDirection direction) {
  if (currency == baseCurrency) {
    throw ArgumentError('An amount in $baseCurrency is not converted');
  }
  return switch (direction) {
    FxDirection.quotePerBase => value.divideBy(rate),
    FxDirection.basePerQuote => value.scaleBy(rate),
  };
}

bool hasRate(LedgerEvent event) {
  if (event.fxSource == FxSource.identity) {
    return event.currency == baseCurrency;
  }
  return event.currency != baseCurrency &&
      event.fxRate != null &&
      event.fxDirection != null;
}

/// [amount], one of [event]'s own fields, in euros at the rate the row was
/// booked at, rounded to the cent half up; null when the row has no rate.
Money? toBase(LedgerEvent event, Money amount) {
  if (!hasRate(event)) return null;
  final rate = event.fxRate;
  final direction = event.fxDirection;
  if (event.fxSource == FxSource.identity ||
      rate == null ||
      direction == null) {
    return amount;
  }
  final converted = inBase(amount, event.currency, rate, direction);
  return Money.parse(converted.amount.roundTo(baseDecimals).toString());
}

/// [toBase] for a row [bookable] already let through.
Money baseOf(LedgerEvent event, Money amount) =>
    toBase(event, amount) ??
    (throw StateError(
      'Ledger entry ${event.id} has no rate to $baseCurrency; '
      'pass the ledger through bookable() first',
    ));

/// The instruments with a trade that cannot be put in euros, by code unit.
List<String> unconvertibleInstrumentIds(List<LedgerEvent> events) {
  final ids = {
    for (final event in events)
      if (event is TradeEvent && !hasRate(event)) event.instrumentId,
  };
  return ids.toList()..sort();
}

/// The ledger with every row of an unconvertible instrument left out, and any
/// other row with no rate on its own.
List<LedgerEvent> bookable(List<LedgerEvent> events) {
  final excluded = unconvertibleInstrumentIds(events).toSet();
  return [
    for (final event in events)
      if (hasRate(event) && !excluded.contains(event.instrumentId)) event,
  ];
}
