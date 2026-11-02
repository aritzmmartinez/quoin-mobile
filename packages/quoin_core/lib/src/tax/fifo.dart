import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../fx/to_base.dart';
import '../money/money.dart';
import '../sort.dart';
import '../swap/values.dart';
import 'config.dart';

final class _FifoLot {
  _FifoLot(this.id, this.quantity, this.unitCost, this.acquiredAt);

  final String id;
  Dec quantity;
  final Money unitCost;
  final DateTime acquiredAt;
}

final class FifoLotConsumption {
  const FifoLotConsumption({
    required this.lotId,
    required this.acquiredAt,
    required this.quantity,
    required this.unitCost,
  });

  final String lotId;
  final DateTime acquiredAt;
  final Dec quantity;
  final Money unitCost;
}

typedef FifoLotBalance = ({String lotId, DateTime acquiredAt, Dec quantity});

final class FifoSale {
  const FifoSale({
    required this.trade,
    required this.gross,
    required this.fees,
    required this.costRemoved,
    required this.realizedPnL,
    required this.lots,
    required this.lotsAfter,
  });

  final TradeEvent trade;
  final Money gross;
  final Money fees;
  final Money costRemoved;
  final Money realizedPnL;
  final List<FifoLotConsumption> lots;
  final List<FifoLotBalance> lotsAfter;

  Dec get quantity => trade.quantity;
}

List<TradeEvent> sortTrades(List<LedgerEvent> events) =>
    stableSorted(bookable(events).whereType<TradeEvent>(), compareTrades);

List<FifoSale> walkFifo(List<LedgerEvent> events, Jurisdiction jurisdiction) {
  final trades = sortTrades(events);
  final amountsOf = tradeAmounts(trades, jurisdiction);
  final queues = <String, List<_FifoLot>>{};
  final sales = <FifoSale>[];

  for (final trade in trades) {
    final queue = queues.putIfAbsent(trade.instrumentId, () => []);
    final amounts = amountsOf(trade);

    if (trade.type == TradeType.buy) {
      queue.add(_FifoLot(
        trade.id,
        trade.quantity,
        trade.quantity.isZero
            ? Money.zero
            : amounts.gross.add(amounts.fees).divideBy(trade.quantity),
        trade.ts,
      ));
      continue;
    }

    var remaining = trade.quantity;
    final consumed = <FifoLotConsumption>[];
    var costRemoved = Money.zero;
    while (remaining > Dec.zero && queue.isNotEmpty) {
      final lot = queue.first;
      final take = minDec(remaining, lot.quantity);
      consumed.add(FifoLotConsumption(
        lotId: lot.id,
        acquiredAt: lot.acquiredAt,
        quantity: take,
        unitCost: lot.unitCost,
      ));
      costRemoved = costRemoved.add(lot.unitCost.scaleBy(take));
      lot.quantity = lot.quantity - take;
      remaining = remaining - take;
      if (lot.quantity.isZero) queue.removeAt(0);
    }

    sales.add(FifoSale(
      trade: trade,
      gross: amounts.gross,
      fees: amounts.fees,
      costRemoved: costRemoved,
      realizedPnL: amounts.gross.subtract(amounts.fees).subtract(costRemoved),
      lots: consumed,
      lotsAfter: [
        for (final lot in queue)
          (lotId: lot.id, acquiredAt: lot.acquiredAt, quantity: lot.quantity),
      ],
    ));
  }

  return sales;
}
