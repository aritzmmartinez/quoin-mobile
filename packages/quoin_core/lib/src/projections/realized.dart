import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../money/money.dart';
import 'avco.dart';

final _msPerDay = Dec.fromInt(Duration.millisecondsPerDay);

final class RealizedSale {
  const RealizedSale({
    required this.eventId,
    required this.ts,
    required this.instrumentId,
    required this.quantity,
    required this.price,
    required this.grossAmount,
    required this.fees,
    required this.costBasis,
    required this.realizedPnL,
    required this.returnPct,
    required this.holdingDays,
  });

  final String eventId;
  final DateTime ts;
  final String instrumentId;
  final Dec quantity;
  final Money? price;
  final Money grossAmount;
  final Money fees;
  final Money costBasis;
  final Money realizedPnL;
  final Dec? returnPct;
  final int? holdingDays;
}

List<RealizedSale> computeRealizedGains(
  List<LedgerEvent> events,
  Jurisdiction jurisdiction,
) =>
    [
      for (final sale in walkAvco(events, jurisdiction).sales)
        RealizedSale(
          eventId: sale.trade.id,
          ts: sale.trade.ts,
          instrumentId: sale.trade.instrumentId,
          quantity: sale.quantity,
          price:
              sale.quantity.isZero ? null : sale.gross.divideBy(sale.quantity),
          grossAmount: sale.gross,
          fees: sale.fees,
          costBasis: sale.costRemoved,
          realizedPnL: sale.realizedPnL,
          returnPct: sale.costRemoved.isZero
              ? null
              : sale.realizedPnL.amount
                  .dividedBy(sale.costRemoved.amount)
                  .roundTo(6),
          holdingDays: switch (sale.acquiredAt) {
            null => null,
            final acquiredAt => int.parse(
                (Dec.fromInt(sale.trade.ts.millisecondsSinceEpoch) - acquiredAt)
                    .dividedBy(_msPerDay)
                    .roundTo(0)
                    .toString(),
              ),
          },
        ),
    ];
