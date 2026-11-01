import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../fx/to_base.dart';
import '../money/money.dart';
import '../sort.dart';
import '../swap/values.dart';

final class Position {
  const Position({
    required this.instrumentId,
    required this.quantity,
    required this.costBasis,
    required this.averageCost,
    required this.realizedPnL,
  });

  final String instrumentId;
  final Dec quantity;
  final Money costBasis;
  final Money averageCost;
  final Money realizedPnL;

  bool get isOpen => !quantity.isZero;
}

/// Current positions by weighted-average cost (AVCO), one per instrument, in
/// the order of each instrument's first trade.
///
/// Trades run in [compareTrades] order whatever the input order, every amount
/// in euros at the rate it was booked at, a swap leg through [tradeAmounts].
/// Only BUY and SELL move a position. FIFO tax lots are a separate projection.
List<Position> computePositions(
  List<LedgerEvent> events,
  Jurisdiction jurisdiction,
) {
  final trades =
      stableSorted(bookable(events).whereType<TradeEvent>(), compareTrades);
  final amountsOf = tradeAmounts(trades, jurisdiction);
  final lots = <String, _Lot>{};

  for (final trade in trades) {
    final lot = lots.putIfAbsent(trade.instrumentId, _Lot.new);
    final amounts = amountsOf(trade);

    if (trade.type == TradeType.buy) {
      lot.costBasis = lot.costBasis.add(amounts.gross).add(amounts.fees);
      lot.quantity = lot.quantity + trade.quantity;
      continue;
    }

    final costRemoved = lot.averageCost.scaleBy(trade.quantity);
    final proceeds = amounts.gross.subtract(amounts.fees);
    lot.realizedPnL = lot.realizedPnL.add(proceeds.subtract(costRemoved));
    lot.costBasis = lot.costBasis.subtract(costRemoved);
    lot.quantity = lot.quantity - trade.quantity;
    if (lot.quantity.isZero) lot.costBasis = Money.zero;
  }

  return [
    for (final MapEntry(key: instrumentId, value: lot) in lots.entries)
      Position(
        instrumentId: instrumentId,
        quantity: lot.quantity,
        costBasis: lot.costBasis,
        averageCost: lot.averageCost,
        realizedPnL: lot.realizedPnL,
      ),
  ];
}

final class _Lot {
  Dec quantity = Dec.zero;
  Money costBasis = Money.zero;
  Money realizedPnL = Money.zero;

  Money get averageCost =>
      quantity.isZero ? Money.zero : costBasis.divideBy(quantity);
}
