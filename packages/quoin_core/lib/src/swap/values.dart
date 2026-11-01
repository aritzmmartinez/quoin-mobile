import '../calendar/day.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../fx/to_base.dart';
import '../money/money.dart';

/// The period a territory values a crypto swap at the greater of its two
/// sides, and the norm that says so.
final class SwapValuationRule {
  const SwapValuationRule({
    required this.territory,
    this.from,
    this.to,
    required this.source,
  });

  final Territory territory;
  final String? from;
  final String? to;
  final String source;
}

const List<SwapValuationRule> swapValuationRules = [
  SwapValuationRule(
    territory: Territory.bizkaia,
    source: 'Arts. 47.1.i, 45.1 y 45.3 NF 13/2013 de Bizkaia; '
        'Art. 47.1.p, redacción de la NF 6/2025',
  ),
];

SwapValuationRule? swapValuationRuleFor(
  Territory territory,
  String swapDay, [
  List<SwapValuationRule> rules = swapValuationRules,
]) {
  for (final rule in rules) {
    if (rule.territory == territory &&
        (rule.from == null || rule.from!.compareTo(swapDay) <= 0) &&
        (rule.to == null || swapDay.compareTo(rule.to!) <= 0)) {
      return rule;
    }
  }
  return null;
}

final class SwapLegValue {
  const SwapLegValue({required this.gross, required this.fees});

  final Money gross;
  final Money fees;
}

final class SwapPairValue {
  const SwapPairValue({required this.sell, required this.buy});

  final SwapLegValue sell;
  final SwapLegValue buy;
}

/// What the ledger stores about a swap, in euros: the value of everything
/// that left (the SELL's gross), the value of what was received before any fee
/// (the BUY's gross plus its fees) and the fee kept from it (the BUY's fees).
final class SwapSides {
  const SwapSides({
    required this.deliveredValue,
    required this.receivedValue,
    required this.receivedFee,
  });

  final Money deliveredValue;
  final Money receivedValue;
  final Money receivedFee;
}

/// The one place a swap's two legs become the figures AVCO and FIFO read.
///
/// With a rule in force, T is the greater of the delivered value and the gross
/// received value; the fee F comes off it once: the SELL's proceeds are T − F
/// (F as its fees) and the BUY's cost is T − F with no fees. With no rule each
/// leg keeps its own market value, the fee still coming off what was received.
SwapPairValue swapPairValue(SwapSides sides, SwapValuationRule? rule) {
  final SwapSides(:deliveredValue, :receivedValue, :receivedFee) = sides;
  if (rule == null) {
    return SwapPairValue(
      sell: SwapLegValue(gross: deliveredValue, fees: Money.zero),
      buy: SwapLegValue(
        gross: receivedValue.subtract(receivedFee),
        fees: Money.zero,
      ),
    );
  }
  final greater = deliveredValue.compareTo(receivedValue) >= 0
      ? deliveredValue
      : receivedValue;
  return SwapPairValue(
    sell: SwapLegValue(gross: greater, fees: receivedFee),
    buy: SwapLegValue(gross: greater.subtract(receivedFee), fees: Money.zero),
  );
}

SwapLegValue _loneLegValue(TradeEvent trade) {
  final gross = baseOf(trade, trade.grossAmount);
  return trade.type == TradeType.sell
      ? SwapLegValue(gross: gross, fees: baseOf(trade, trade.fees))
      : SwapLegValue(gross: gross, fees: Money.zero);
}

typedef TradeAmounts = SwapLegValue Function(TradeEvent trade);

/// The gross and fees, in euros, a trade is booked at. A swap leg is valued
/// with the leg it is linked to, by the rule in force on the day of the swap;
/// a leg that does not pair as exactly one SELL and one BUY keeps its own
/// market value. [events] must already be [bookable].
TradeAmounts tradeAmounts(
  List<LedgerEvent> events,
  Jurisdiction jurisdiction, [
  List<SwapValuationRule> rules = swapValuationRules,
]) {
  final groups = <String, List<TradeEvent>>{};
  for (final event in events) {
    final linkId = event.linkId;
    if (event is TradeEvent && isSwapLeg(event) && linkId != null) {
      groups.putIfAbsent(linkId, () => []).add(event);
    }
  }

  final values = <String, SwapLegValue>{};
  for (final group in groups.values) {
    final sells = [
      for (final leg in group)
        if (leg.type == TradeType.sell) leg
    ];
    final buys = [
      for (final leg in group)
        if (leg.type == TradeType.buy) leg
    ];
    if (sells.length == 1 && buys.length == 1) {
      final sell = sells.single;
      final buy = buys.single;
      final pair = swapPairValue(
        SwapSides(
          deliveredValue: baseOf(sell, sell.grossAmount),
          receivedValue:
              baseOf(buy, buy.grossAmount).add(baseOf(buy, buy.fees)),
          receivedFee: baseOf(buy, buy.fees),
        ),
        swapValuationRuleFor(
          jurisdiction.territory,
          dayOf(sell.ts, jurisdiction.zone),
          rules,
        ),
      );
      values[sell.id] = pair.sell;
      values[buy.id] = pair.buy;
    } else {
      for (final leg in group) {
        values[leg.id] = _loneLegValue(leg);
      }
    }
  }

  return (trade) =>
      values[trade.id] ??
      SwapLegValue(
        gross: baseOf(trade, trade.grossAmount),
        fees: baseOf(trade, trade.fees),
      );
}
