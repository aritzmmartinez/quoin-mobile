import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../money/money.dart';
import '../sort.dart';
import 'market_value.dart';
import 'positions.dart';

final class PortfolioSummary {
  const PortfolioSummary({
    required this.totalValue,
    required this.totalInvested,
    required this.openCost,
    required this.pricedCost,
    required this.unpricedCost,
    required this.unrealizedPnL,
    required this.realizedPnL,
    required this.returnPct,
    required this.pricedCount,
    required this.unpricedCount,
  });

  /// Value of the priced open positions.
  final Money totalValue;

  /// Cost of the priced open positions.
  final Money totalInvested;

  /// Cost of every open position, priced or not.
  final Money openCost;
  final Money pricedCost;

  /// Cost of the open positions with no price: named, never added to the value.
  final Money unpricedCost;
  final Money unrealizedPnL;
  final Money realizedPnL;

  /// Unrealized P&L over [totalInvested]; null when nothing priced cost money.
  final Dec? returnPct;
  final int pricedCount;
  final int unpricedCount;
}

PortfolioSummary computePortfolioSummary(
  List<Position> positions,
  Map<String, MarketValue> marketValues,
) {
  var totalValue = Money.zero;
  var totalInvested = Money.zero;
  var unpricedCost = Money.zero;
  var realizedPnL = Money.zero;
  var pricedCount = 0;
  var unpricedCount = 0;

  for (final position in positions) {
    realizedPnL = realizedPnL.add(position.realizedPnL);
    if (!position.isOpen) continue;

    final value = marketValues[position.instrumentId]?.marketValue;
    if (value == null) {
      unpricedCount += 1;
      unpricedCost = unpricedCost.add(position.costBasis);
      continue;
    }
    totalValue = totalValue.add(value);
    totalInvested = totalInvested.add(position.costBasis);
    pricedCount += 1;
  }

  final unrealizedPnL = totalValue.subtract(totalInvested);
  return PortfolioSummary(
    totalValue: totalValue,
    totalInvested: totalInvested,
    openCost: totalInvested.add(unpricedCost),
    pricedCost: totalInvested,
    unpricedCost: unpricedCost,
    unrealizedPnL: unrealizedPnL,
    realizedPnL: realizedPnL,
    returnPct:
        totalInvested.isZero ? null : ratio(unrealizedPnL, totalInvested),
    pricedCount: pricedCount,
    unpricedCount: unpricedCount,
  );
}

Set<String> unpricedOpenIds(
  List<Position> positions,
  Map<String, MarketValue> marketValues,
) =>
    {
      for (final p in positions)
        if (p.isOpen && marketValues[p.instrumentId]?.marketValue == null)
          p.instrumentId,
    };

const String otherCategory = 'OTHER';

final class AllocationSlice {
  const AllocationSlice({
    required this.category,
    required this.value,
    required this.weight,
  });

  final String category;
  final Money value;
  final Dec weight;
}

/// Priced value by category, largest first, ties by category code. An
/// instrument with no category falls into [fallbackCategory].
List<AllocationSlice> computeAllocation(
  List<Position> positions,
  Map<String, MarketValue> marketValues,
  Map<String, String> categories, {
  String fallbackCategory = otherCategory,
}) {
  final totals = <String, Money>{};
  var total = Money.zero;

  for (final position in positions) {
    final value = marketValues[position.instrumentId]?.marketValue;
    if (value == null || value.isZero) continue;
    final category = categories[position.instrumentId] ?? fallbackCategory;
    totals[category] = (totals[category] ?? Money.zero).add(value);
    total = total.add(value);
  }

  if (total.isZero) return [];
  return stableSorted(
    [
      for (final MapEntry(key: category, value: value) in totals.entries)
        AllocationSlice(
          category: category,
          value: value,
          weight: ratio(value, total),
        ),
    ],
    (a, b) {
      final byValue = b.value.compareTo(a.value);
      return byValue != 0 ? byValue : compareCodeUnits(a.category, b.category);
    },
  );
}

final class TopPosition {
  const TopPosition({
    required this.instrumentId,
    required this.marketValue,
    required this.weight,
    required this.unrealizedPnL,
    required this.unrealizedPnLPct,
  });

  final String instrumentId;
  final Money marketValue;
  final Dec weight;
  final Money unrealizedPnL;

  /// Null when the position cost nothing.
  final Dec? unrealizedPnLPct;
}

/// The [limit] largest open priced positions, ties by instrument id.
List<TopPosition> computeTopPositions(
  List<Position> positions,
  Map<String, MarketValue> marketValues, [
  int limit = 5,
]) {
  final rows = <TopPosition>[];
  for (final position in positions) {
    if (!position.isOpen) continue;
    final value = marketValues[position.instrumentId];
    final (marketValue, unrealizedPnL, weight) = (
      value?.marketValue,
      value?.unrealizedPnL,
      value?.weight,
    );
    if (marketValue == null || unrealizedPnL == null || weight == null) {
      continue;
    }
    rows.add(
      TopPosition(
        instrumentId: position.instrumentId,
        marketValue: marketValue,
        weight: weight,
        unrealizedPnL: unrealizedPnL,
        unrealizedPnLPct: position.costBasis.isZero
            ? null
            : ratio(unrealizedPnL, position.costBasis),
      ),
    );
  }
  return stableSorted(rows, (a, b) {
    final byValue = b.marketValue.compareTo(a.marketValue);
    return byValue != 0
        ? byValue
        : compareCodeUnits(a.instrumentId, b.instrumentId);
  }).take(limit).toList();
}
