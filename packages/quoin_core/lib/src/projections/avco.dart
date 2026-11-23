import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../fx/to_base.dart';
import '../money/money.dart';
import '../sort.dart';
import '../swap/values.dart';

final class AvcoLot {
  AvcoLot(this.instrumentId);

  final String instrumentId;
  Dec quantity = Dec.zero;
  Money costBasis = Money.zero;
  Money realizedPnL = Money.zero;
  Dec? acquiredAt;

  Money get averageCost =>
      quantity.isZero ? Money.zero : costBasis.divideBy(quantity);
}

final class AvcoSale {
  const AvcoSale({
    required this.trade,
    required this.gross,
    required this.fees,
    required this.costRemoved,
    required this.realizedPnL,
    required this.acquiredAt,
  });

  final TradeEvent trade;
  final Money gross;
  final Money fees;
  final Money costRemoved;
  final Money realizedPnL;
  final Dec? acquiredAt;

  Dec get quantity => trade.quantity;
}

typedef AvcoWalk = ({Map<String, AvcoLot> lots, List<AvcoSale> sales});

AvcoWalk walkAvco(List<LedgerEvent> events, Jurisdiction jurisdiction) {
  final trades =
      stableSorted(bookable(events).whereType<TradeEvent>(), compareTrades);
  final amountsOf = tradeAmounts(trades, jurisdiction);
  final lots = <String, AvcoLot>{};
  final sales = <AvcoSale>[];

  for (final trade in trades) {
    final lot =
        lots.putIfAbsent(trade.instrumentId, () => AvcoLot(trade.instrumentId));
    final amounts = amountsOf(trade);

    if (trade.type == TradeType.buy) {
      lot.acquiredAt = _blendAcquisition(lot, trade);
      lot.costBasis = lot.costBasis.add(amounts.gross).add(amounts.fees);
      lot.quantity = lot.quantity + trade.quantity;
      continue;
    }

    final costRemoved = lot.averageCost.scaleBy(trade.quantity);
    final realizedPnL =
        amounts.gross.subtract(amounts.fees).subtract(costRemoved);
    sales.add(AvcoSale(
      trade: trade,
      gross: amounts.gross,
      fees: amounts.fees,
      costRemoved: costRemoved,
      realizedPnL: realizedPnL,
      acquiredAt: lot.acquiredAt,
    ));

    lot.realizedPnL = lot.realizedPnL.add(realizedPnL);
    lot.costBasis = lot.costBasis.subtract(costRemoved);
    lot.quantity = lot.quantity - trade.quantity;
    if (lot.quantity.isZero) {
      lot.costBasis = Money.zero;
      lot.acquiredAt = null;
    }
  }

  return (lots: lots, sales: sales);
}

Dec? _blendAcquisition(AvcoLot lot, TradeEvent buy) {
  final bought = Dec.fromInt(buy.ts.millisecondsSinceEpoch);
  final held = lot.acquiredAt;
  if (buy.quantity.isZero) return held;
  if (held == null || lot.quantity <= Dec.zero) return bought;
  return (held * lot.quantity + bought * buy.quantity)
      .dividedBy(lot.quantity + buy.quantity);
}
