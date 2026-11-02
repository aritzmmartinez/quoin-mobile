import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';

List<Movement> movementsOf(PortfolioLedger ledger) {
  final names = {for (final i in ledger.instruments) i.id: i.name};
  String nameOf(String id) => names[id] ?? id;
  final routes = _swapRoutes(ledger.events, nameOf);

  final events = [...ledger.events]
    ..sort((a, b) {
      final byTs = b.ts.compareTo(a.ts);
      if (byTs != 0) return byTs;
      final byExternal = compareCodeUnits(
        a.externalId ?? '',
        b.externalId ?? '',
      );
      return byExternal != 0 ? byExternal : compareCodeUnits(a.id, b.id);
    });

  return [
    for (final event in events)
      Movement(
        id: event.id,
        ts: event.ts,
        type: ledgerTypeOf(event),
        inKind: isInKind(event),
        swapRoute: isSwapLeg(event) ? routes[event.linkId] ?? '' : null,
        instrumentId: event.instrumentId,
        instrumentName: switch (event.instrumentId) {
          null => null,
          final id => nameOf(id),
        },
        quantity: event is TradeEvent ? event.quantity : null,
        amount: _amount(event),
        currency: event.currency,
        converted: event.currency != baseCurrency && hasRate(event),
      ),
  ];
}

Money? _amount(LedgerEvent event) {
  if (!hasRate(event)) return null;
  final (gross, costs, outflow) = switch (event) {
    TradeEvent(:final type, :final grossAmount, :final fees) => (
      grossAmount,
      fees,
      type == TradeType.buy,
    ),
    DividendEvent(:final grossAmount, :final taxWithheld) => (
      grossAmount,
      taxWithheld,
      false,
    ),
    CashEvent(:final type, :final grossAmount) => (
      grossAmount,
      Money.zero,
      type == CashType.withdrawal,
    ),
  };
  final base = baseOf(event, gross);
  if (isSwapLeg(event)) return base;
  return (outflow ? base.negate() : base).subtract(baseOf(event, costs));
}

Map<String, String> _swapRoutes(
  List<LedgerEvent> events,
  String Function(String id) nameOf,
) {
  final legs = <String, ({List<String> sells, List<String> buys})>{};
  for (final event in events) {
    final link = event.linkId;
    if (event is! TradeEvent || !isSwapLeg(event) || link == null) continue;
    final group = legs.putIfAbsent(link, () => (sells: [], buys: []));
    (event.type == TradeType.sell ? group.sells : group.buys).add(
      event.instrumentId,
    );
  }
  return {
    for (final MapEntry(key: link, value: (:sells, :buys)) in legs.entries)
      if (sells.length == 1 && buys.length == 1)
        link: '${nameOf(sells.single)} → ${nameOf(buys.single)}',
  };
}
