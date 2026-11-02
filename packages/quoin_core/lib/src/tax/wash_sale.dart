import '../calendar/calendar_date.dart';
import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../sort.dart';
import 'config.dart';
import 'fifo.dart';

typedef WashSaleWindow = ({CalendarDate start, CalendarDate end});

WashSaleWindow washSaleWindow(DateTime saleTs, int months, String zone) {
  final sale = calendarDateOf(saleTs, zone);
  return (
    start: addCalendarMonths(sale, -months),
    end: addCalendarMonths(sale, months),
  );
}

final class RepurchaseScope {
  const RepurchaseScope({
    required this.jurisdiction,
    required this.assetClasses,
    this.rules = repurchaseRules,
  });

  final Jurisdiction jurisdiction;
  final Map<String, RepurchaseAssetClass> assetClasses;
  final List<RepurchaseRule> rules;
}

typedef WashSaleRecipient = ({
  String buyEventId,
  DateTime acquiredAt,
  Dec quantity
});

final class WashSaleAssessment {
  const WashSaleAssessment({
    required this.window,
    required this.before,
    required this.remainingAfter,
    required this.repurchaseBefore,
    required this.repurchaseAfter,
    required this.repurchased,
    required this.fraction,
    required this.recipients,
    required this.rule,
  });

  final WashSaleWindow window;
  final Dec before;
  final Dec remainingAfter;
  final Dec repurchaseBefore;
  final Dec repurchaseAfter;
  final Dec repurchased;
  final Dec fraction;
  final List<WashSaleRecipient> recipients;
  final RepurchaseRule rule;
}

typedef UnlistedRepurchaseNotice = ({String buyEventId, DateTime buyTs});

final class WashSaleAssessor {
  WashSaleAssessor(List<TradeEvent> trades, this._scope) {
    final ordered = stableSorted(trades, compareTrades);
    for (final (i, trade) in ordered.indexed) {
      _position[trade.id] = i;
      if (trade.type == TradeType.buy) {
        _buys.putIfAbsent(trade.instrumentId, () => []).add(trade);
      }
    }
  }

  final RepurchaseScope _scope;
  final _position = <String, int>{};
  final _buys = <String, List<TradeEvent>>{};
  final _used = <String, Dec>{};

  String get _zone => _scope.jurisdiction.zone;

  RepurchaseAssetClass assetClassOf(String instrumentId) =>
      _scope.assetClasses[instrumentId] ??
      (throw StateError('No repurchase asset class for $instrumentId'));

  RepurchaseRule? ruleFor(FifoSale sale) => repurchaseRuleFor(
        _scope.jurisdiction.territory,
        assetClassOf(sale.trade.instrumentId),
        calendarDateOf(sale.trade.ts, _zone),
        _scope.rules,
      );

  Dec _free(TradeEvent buy) =>
      maxDec(buy.quantity - (_used[buy.id] ?? Dec.zero), Dec.zero);

  int _at(String id, int missing) => _position[id] ?? missing;

  WashSaleAssessment assess(FifoSale sale, RepurchaseRule rule) {
    final saleAt = _at(sale.trade.id, -1);
    final window = washSaleWindow(sale.trade.ts, rule.windowMonths, _zone);
    final inWindow = [
      for (final buy in _buys[sale.trade.instrumentId] ?? const <TradeEvent>[])
        if ((!rule.cashOnly || !isInKind(buy)) &&
            isWithin(calendarDateOf(buy.ts, _zone), window.start, window.end))
          buy,
    ];
    final earlier = [
      for (final b in inWindow)
        if (_at(b.id, 0) < saleAt) b,
    ];
    final later = [
      for (final b in inWindow)
        if (_at(b.id, 0) > saleAt) b,
    ];

    final before = sumDec(earlier.map(_free));
    final remainingAfter = sumDec(sale.lotsAfter.map((lot) => lot.quantity));

    final earlierById = {for (final b in earlier) b.id: b};
    final held = <WashSaleRecipient>[];
    for (final lot in sale.lotsAfter) {
      final buy = earlierById[lot.lotId];
      if (buy == null) continue;
      final quantity = minDec(lot.quantity, _free(buy));
      if (quantity > Dec.zero) {
        held.add((buyEventId: buy.id, acquiredAt: buy.ts, quantity: quantity));
      }
    }

    final repurchaseBefore = minDec(
      minDec(before, remainingAfter),
      sumDec(held.map((h) => h.quantity)),
    );
    final repurchaseAfter = sumDec(later.map(_free));
    final repurchased =
        minDec(repurchaseBefore + repurchaseAfter, sale.quantity);

    final recipients = <WashSaleRecipient>[];
    var open = minDec(repurchaseBefore, repurchased);
    for (final h in held) {
      if (open <= Dec.zero) break;
      final take = minDec(open, h.quantity);
      recipients.add((
        buyEventId: h.buyEventId,
        acquiredAt: h.acquiredAt,
        quantity: take,
      ));
      open = open - take;
    }
    open = repurchased - sumDec(recipients.map((r) => r.quantity));
    for (final buy in later) {
      if (open <= Dec.zero) break;
      final take = minDec(open, _free(buy));
      if (take <= Dec.zero) continue;
      recipients.add((buyEventId: buy.id, acquiredAt: buy.ts, quantity: take));
      open = open - take;
    }
    for (final r in recipients) {
      _used[r.buyEventId] = (_used[r.buyEventId] ?? Dec.zero) + r.quantity;
    }

    return WashSaleAssessment(
      window: window,
      before: before,
      remainingAfter: remainingAfter,
      repurchaseBefore: repurchaseBefore,
      repurchaseAfter: repurchaseAfter,
      repurchased: repurchased,
      fraction: sale.quantity > Dec.zero
          ? repurchased.dividedBy(sale.quantity)
          : Dec.zero,
      recipients: recipients,
      rule: rule,
    );
  }

  UnlistedRepurchaseNotice? unlistedNotice(FifoSale sale) {
    final saleAt = _at(sale.trade.id, -1);
    final start = calendarDateOf(sale.trade.ts, _zone);
    final end = addCalendarMonths(start, unlistedNoticeWindowMonths);
    for (final buy in _buys[sale.trade.instrumentId] ?? const <TradeEvent>[]) {
      if (_at(buy.id, 0) > saleAt &&
          isWithin(calendarDateOf(buy.ts, _zone), start, end)) {
        return (buyEventId: buy.id, buyTs: buy.ts);
      }
    }
    return null;
  }
}
