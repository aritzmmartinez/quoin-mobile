import '../decimal/dec.dart';
import '../fx/value.dart';
import '../money/money.dart';
import 'positions.dart';

/// Ratios are kept to six places, as the web stores them.
const int ratioDecimals = 6;

Dec ratio(Money part, Money whole) =>
    part.amount.dividedBy(whole.amount).roundTo(ratioDecimals);

/// A position's value; every field is null when it has no price.
final class MarketValue {
  const MarketValue({this.marketValue, this.unrealizedPnL, this.weight});

  final Money? marketValue;
  final Money? unrealizedPnL;

  /// Share of the total priced value; weights sum to one across priced
  /// positions.
  final Dec? weight;
}

/// Market value, unrealized P&L and weight per position, by instrument.
///
/// [prices] must already be in euros ([pricesInBase] is where a price with no
/// rate is left out); a price in another currency throws.
Map<String, MarketValue> computeMarketValues(
  List<Position> positions,
  Map<String, PriceSnapshot> prices,
) {
  final values = <String, Money?>{};
  var total = Money.zero;

  for (final position in positions) {
    final price = prices[position.instrumentId];
    if (price == null) {
      values[position.instrumentId] = null;
      continue;
    }
    if (price.currency != baseCurrency) {
      throw ArgumentError(
        'Price of ${position.instrumentId} is in ${price.currency}, not '
        '$baseCurrency; pass prices through pricesInBase() first',
      );
    }
    final value = price.price.scaleBy(position.quantity);
    values[position.instrumentId] = value;
    total = total.add(value);
  }

  final costs = {for (final p in positions) p.instrumentId: p.costBasis};
  return {
    for (final MapEntry(key: id, value: value) in values.entries)
      id: value == null
          ? const MarketValue()
          : MarketValue(
              marketValue: value,
              unrealizedPnL: value.subtract(costs[id]!),
              weight: total.isPositive ? ratio(value, total) : null,
            ),
  };
}
