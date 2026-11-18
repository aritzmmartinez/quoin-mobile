import 'package:quoin_core/quoin_core.dart';

class Holding {
  const Holding({
    required this.instrumentId,
    required this.name,
    required this.type,
    required this.category,
    required this.position,
    required this.value,
  });

  final String instrumentId;
  final String name;
  final String type;
  final String category;
  final Position position;
  final MarketValue value;

  bool get isPriced => value.marketValue != null;

  Dec? get unrealizedPnLPct {
    final pnl = value.unrealizedPnL;
    if (pnl == null || position.costBasis.isZero) return null;
    return ratio(pnl, position.costBasis);
  }
}

class HoldingGroup {
  const HoldingGroup({
    required this.category,
    required this.holdings,
    required this.value,
  });

  final String category;
  final List<Holding> holdings;
  final Money? value;
}

List<HoldingGroup> groupByCategory(
  List<Holding> holdings,
  List<AllocationSlice> allocation,
) {
  final byCategory = <String, List<Holding>>{};
  for (final h in holdings) {
    (byCategory[h.category] ??= []).add(h);
  }
  final order = [
    for (final slice in allocation)
      if (slice.category != otherCategory) slice.category,
    for (final category in byCategory.keys)
      if (category != otherCategory &&
          !allocation.any((s) => s.category == category))
        category,
    otherCategory,
  ];
  return [
    for (final category in order)
      if (byCategory[category] case final group?)
        HoldingGroup(
          category: category,
          holdings: group,
          value: group.any((h) => h.isPriced)
              ? group.fold<Money>(
                  Money.zero,
                  (sum, h) => sum.add(h.value.marketValue ?? Money.zero),
                )
              : null,
        ),
  ];
}

enum ValuationGap { leftOut, noRate, noPrice }

class ValuationIssue {
  const ValuationIssue({
    required this.instrumentId,
    required this.name,
    required this.gap,
    this.currency,
  });

  final String instrumentId;
  final String name;
  final ValuationGap gap;
  final String? currency;
}

class PortfolioOverview {
  const PortfolioOverview({
    required this.hasLedger,
    required this.summary,
    required this.holdings,
    required this.allocation,
    required this.top,
    required this.issues,
    required this.unconvertible,
  });

  final bool hasLedger;
  final PortfolioSummary summary;
  final List<Holding> holdings;
  final List<AllocationSlice> allocation;
  final List<Holding> top;
  final List<ValuationIssue> issues;
  final List<String> unconvertible;
}
